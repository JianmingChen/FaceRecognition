import Firebase
import FirebaseFirestore

class FireBaseServer {
    static let shared = FireBaseServer()
    private let db = Firestore.firestore()

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
}
