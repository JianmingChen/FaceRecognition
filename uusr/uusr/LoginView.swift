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
            Text("User Selfie Register")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            
            Button(action: { authenticateUser() }) {
                Text("Login")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if isLoginFailed {
                Text("Invalid email or password")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            Button(action: { showingFaceScanner.toggle() }) {
                Label("Face Sign-In", systemImage: "faceid")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showingFaceScanner) {
                FaceCaptureView(
                    capturedImage: $capturedImage,
                    mode: .login,
                    onFrameCaptured: { image in
                        authenticateWithFace(image: image)
                    }
                )
            }
            
            Button(action: { showRegistration.toggle() }) {
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
    
    func authenticateUser() {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                self.isLoginFailed = true
                return
            }
            
            guard let documents = querySnapshot?.documents, let document = documents.first else {
                print("No matching user found.")
                self.isLoginFailed = true
                return
            }
            
            let data = document.data()
            if let storedPassword = data["password"] as? String, storedPassword == self.password {
                print("Password match successful.")
                self.isLoginFailed = false
                userViewModel.isLoggedIn = true
            } else {
                print("Password mismatch.")
                self.isLoginFailed = true
            }
        }
    }
    
    func authenticateWithFace(image: UIImage) {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                self.isLoginFailed = true
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No users found in database.")
                self.isLoginFailed = true
                return
            }

            // Extract the face embedding from the captured image
            FaceRecognitionManager.shared.getEmbedding(from: image) { embedding in
                DispatchQueue.main.async {
                    guard let capturedMetrics = embedding else {
                        print("Face encoding failed for login.")
                        self.isLoginFailed = true
                        return
                    }

                    var bestMatch: String?
                    var highestSimilarity: Float = 0

                    // Compare with stored user face embeddings
                    for document in documents {
                        let data = document.data()
                        if let storedMetrics = data["faceEncoding"] as? [Float] {
                            let similarity = FaceRecognitionManager.shared.cosineSimilarity(a: capturedMetrics, b: storedMetrics)
                            print("Similarity with user \(document.documentID): \(similarity)")  // Print similarity

                            // If similarity is higher than the previous one, update best match
                            if similarity > highestSimilarity {
                                highestSimilarity = similarity
                                bestMatch = document.documentID
                            }
                        }
                    }

                    // Apply the threshold for the highest similarity
                    if let matchedUserId = bestMatch, highestSimilarity >= 0.80 {
                        print("Face recognition successful for user ID: \(matchedUserId)")
                        self.isLoginFailed = false
                        userViewModel.isLoggedIn = true
                    } else {
                        print("No matching face found or similarity below threshold.")
                        self.isLoginFailed = true
                    }
                }
            }
        }
    }
}
