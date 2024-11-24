import Firebase
import FirebaseFirestore
import FirebaseStorage

class FireBaseServer {
    static let shared = FireBaseServer()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()


    // Fetch all clients from Firestore
    func fetchClients(completion: @escaping ([User]?, Error?) -> Void) {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion([], nil)
                return
            }
            
            let clients = documents.compactMap { document in
                let data = document.data()
                return User(
                    email: data["email"] as? String ?? "",
                    password: data["password"] as? String ?? "",
                    role: (data["role"] as? String == "manager") ? .manager : .individual,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    unitNumber: data["unitNumber"] as? String,
                    buildingName: data["buildingName"] as? String,
                    statusDictionary: data["status"] as? [String: Bool] ?? [:]
                )
            }
            completion(clients, nil)
        }
    }

    // Register a new user
    func registerUser(user: User, faceEncoding: [[String: Any]], completion: @escaping (Error?) -> Void) {
        var userData: [String: Any] = [
            "id": user.id.uuidString,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "password": user.password,
            "unitNumber": user.unitNumber ?? "",
            "buildingName": user.buildingName ?? "",
            "role": user.role == .manager ? "manager" : "individual",
            "status": Status.allCases.reduce(into: [String: Bool]()) { $0[$1.rawValue] = false },
            "faceEncoding": faceEncoding
        ]
        
        db.collection("users").document(user.id.uuidString).setData(userData) { error in
            completion(error)
        }
    }

    // Update user status in Firestore
    func updateStatus(for userId: String, status: [String: Bool], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).updateData(["status": status]) { error in
            completion(error)
        }
    }

    // Validate user session
    func validateSession(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            completion(document?.exists ?? false)
        }
    }

     // Authenticate user by email and password
    func authenticateUser(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let documents = querySnapshot?.documents, let document = documents.first else {
                completion(false, nil) // No user found
                return
            }
            
            let data = document.data()
            if let storedPassword = data["password"] as? String, storedPassword == password {
                completion(true, nil) // Successful login
            } else {
                completion(false, nil) // Incorrect password
            }
        }
    }

    // Authenticate user by face recognition
    func authenticateWithFace(image: UIImage, completion: @escaping (String?, Float, Error?) -> Void) {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(nil, 0, error)
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(nil, 0, nil) // No users found
                return
            }
            
            FaceRecognitionManager.shared.encodeFace(from: image, for: "tempUser") { success, capturedEncoding in
                guard success, let capturedEncoding = capturedEncoding else {
                    completion(nil, 0, NSError(domain: "FaceEncodingFailed", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode face"]))
                    return
                }
                
                var bestMatch: String?
                var highestSimilarity: Float = 0
                
                for document in documents {
                    let data = document.data()
                    if let storedEncoding = data["faceEncoding"] as? [[String: CGFloat]] {
                        let storedPoints = storedEncoding.map { CGPoint(x: $0["x"] ?? 0, y: $0["y"] ?? 0) }
                        let similarity = FaceRecognitionManager.shared.calculateSimilarity(points1: capturedEncoding, points2: storedPoints)
                        
                        if similarity > highestSimilarity {
                            highestSimilarity = similarity
                            bestMatch = document.documentID
                        }
                    }
                }
                
                completion(bestMatch, highestSimilarity, nil)
            }
        }
    }
        func uploadFaceImage(faceImage: UIImage, userId: String, completion: @escaping (Error?) -> Void) {
        guard let imageData = faceImage.jpegData(compressionQuality: 0.8) else {
            completion(NSError(domain: "InvalidImage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"]))
            return
        }
        
        let storageRef = storage.reference()
        let imageRef = storageRef.child("faces/\(userId).jpg")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            completion(error)
        }
    }
}
