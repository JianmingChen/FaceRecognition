import SwiftUI

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
            
            if isLoginFailed {
                Text("Invalid email or password")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
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
    
    func authenticateUser() {
        FireBaseServer.shared.authenticateUser(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    isLoginFailed = true
                } else {
                    isLoginFailed = !success
                    if success {
                        userViewModel.isLoggedIn = true
                    }
                }
            }
        }
    }
    
    func authenticateWithFace(image: UIImage) {
        FireBaseServer.shared.authenticateWithFace(image: image) { matchedUserId, similarity, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    isLoginFailed = true
                } else if let userId = matchedUserId, similarity > 0.8 {
                    print("Face matched with user ID: \(userId), Similarity: \(similarity)")
                    isLoginFailed = false
                    userViewModel.isLoggedIn = true
                } else {
                    print("No face match found. Similarity: \(similarity)")
                    isLoginFailed = true
                }
            }
        }
    }
}
