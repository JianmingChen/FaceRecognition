import SwiftUI
import Firebase
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoginFailed = false
    @State private var showRegistration = false
    @State private var showingFaceScanner = false
    @State private var capturedImage: UIImage?
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        VStack(spacing: 20) {
            // App Title
            Text("User Selfie Register")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            // Email Field
            TextField("Email", text: $email)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            // Password Field
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            
            // Login Button
            Button(action: {
                authenticateUser()
            }) {
                Text("Login")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            // Error Message
            if isLoginFailed {
                Text("Invalid email or password")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            // Face Sign-In Button
            Button(action: {
                showingFaceScanner.toggle()
            }) {
                Label("Face Sign-In", systemImage: "faceid")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showingFaceScanner) {
                FaceCaptureView(capturedImage: $capturedImage) { success in
                    if success, let image = capturedImage {
                        authenticateWithFace(image: image)
                    }
                }
            }
            
            // Register Button
            Button(action: {
                showRegistration.toggle()
            }) {
                Text("Register").foregroundColor(.blue)
            }
            .padding(.top, 10)
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Authenticate user using email and password
    func authenticateUser() {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                self.isLoginFailed = true
                return
            }
            
            guard let documents = querySnapshot?.documents, let document = documents.first else {
                print("No matching documents found.")
                self.isLoginFailed = true
                return
            }
            
            let data = document.data()
            if let storedPassword = data["password"] as? String, storedPassword == self.password {
                print("Login successful for email: \(email)")
                self.isLoginFailed = false
                userViewModel.isLoggedIn = true
            } else {
                print("Incorrect password for email: \(email)")
                self.isLoginFailed = true
            }
        }
    }
    
    // Authenticate user using face recognition
    func authenticateWithFace(image: UIImage) {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                self.isLoginFailed = true
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No users found.")
                self.isLoginFailed = true
                return
            }
            
            FaceRecognitionManager.shared.encodeFace(from: image, for: "tempUser") { success, capturedEncoding in
                guard success, let capturedEncoding = capturedEncoding else {
                    print("Failed to encode face.")
                    self.isLoginFailed = true
                    return
                }
                
                var bestMatch: String?
                var highestSimilarity: Float = 0
                
                // Compare captured face encoding with stored encodings
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
                
                // Check if the best match meets the similarity threshold
                DispatchQueue.main.async {
                    if let matchedUserId = bestMatch, highestSimilarity > 0.8 {
                        print("Face matched with user ID: \(matchedUserId), Similarity: \(highestSimilarity)")
                        self.isLoginFailed = false
                        userViewModel.isLoggedIn = true
                    } else {
                        print("No face match found.")
                        self.isLoginFailed = true
                    }
                }
            }
        }
    }
}
