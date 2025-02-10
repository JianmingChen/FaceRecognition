import SwiftUI
import Firebase
import FirebaseFirestore

struct RegistrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var unitNumber: String = ""
    @State private var buildingName: String = ""
    @State private var password: String = ""
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage? = nil
    @State private var isEmailInvalid = false
    @State private var capturedImage: UIImage?
    @State private var showingFaceCapture = false
    @State private var faceVerificationStatus: String?
    @State private var showSuccessAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                HStack(spacing: 20) {
                    // Profile Image Section
                    VStack {
                        if profileImage != nil {
                            Image(uiImage: profileImage!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .padding(.bottom, 5)
                        } else {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(Text("Add Photo").foregroundColor(.blue))
                            }
                        }
                    }
                    .sheet(isPresented: $showingImagePicker) {
                        ImagePicker(selectedImage: $profileImage)
                    }
                    
                    // Capture Face ID Section
                    Button(action: {
                        showingFaceCapture = true
                    }) {
                        VStack {
                            Image(systemName: "faceid")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .padding(.bottom, 5)
                            Text("Capture Face ID")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 120, height: 100)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingFaceCapture) {
                        FaceCaptureView(capturedImage: $capturedImage) { success in
                            if success {
                                verifyFace()
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                
                if let status = faceVerificationStatus {
                    Text(status)
                        .foregroundColor(status.contains("Success") ? .green : .red)
                        .padding(.top, 5)
                }
                
                TextField("First Name", text: $firstName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                TextField("Last Name", text: $lastName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .onChange(of: email) { newValue in
                        isEmailInvalid = !isValidEmail(newValue)
                    }
                
                if isEmailInvalid {
                    Text("Invalid email address")
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.bottom, 5)
                }
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                TextField("Unit Number", text: $unitNumber)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                TextField("Building Name", text: $buildingName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                Button(action: {
                    if !isEmailInvalid {
                        registerUser()
                    }
                }) {
                    Text("Register")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                .disabled(isEmailInvalid)
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Registration Successful"),
                    message: Text("Your account has been successfully created."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }

    func compressEncoding(_ encoding: [CGPoint]) -> [Float] {
        return encoding.map { Float(($0.x + $0.y) / 2) }
    }

    func registerUser() {
        // Create a unique user ID
        let userId = UUID().uuidString

        if let faceImage = capturedImage {
            // If Face ID is provided, process it
            FaceRecognitionManager.shared.encodeFace(from: faceImage, for: userId) { success, points in
                DispatchQueue.main.async {
                    if success, let faceEncoding = points {
                        let compressedEncoding = self.compressEncoding(faceEncoding)
                        
                        // Register user with face encoding
                        self.saveUserToFirestore(userId: userId, faceEncoding: compressedEncoding)
                    } else {
                        self.faceVerificationStatus = "Face encoding failed. Registering without Face ID."
                        
                        // Register user without face encoding
                        self.saveUserToFirestore(userId: userId, faceEncoding: nil)
                    }
                }
            }
        } else {
            // Register user without Face ID
            saveUserToFirestore(userId: userId, faceEncoding: nil)
        }
    }

    func saveUserToFirestore(userId: String, faceEncoding: [Float]?) {
        // Prepare user data
        var newUser: [String: Any] = [
            "firstName": self.firstName,
            "lastName": self.lastName,
            "email": self.email,
            "password": self.password,
            "unitNumber": self.unitNumber,
            "buildingName": self.buildingName
        ]
        
        if let faceEncoding = faceEncoding {
            newUser["faceEncoding"] = faceEncoding
        }
        
        // Save user to Firestore
        Firestore.firestore().collection("users").document(userId).setData(newUser) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.faceVerificationStatus = "Failed to register user: \(error.localizedDescription)"
                } else {
                    self.faceVerificationStatus = "User successfully registered"
                    self.showSuccessAlert = true
                }
            }
        }
        let photoId = (newUser["email"] as! String).replacingOccurrences(of: ".com", with: "").replacingOccurrences(of: "@", with: "")
        print(photoId)
        
        // Save photo of user to photo server
        guard let img = profileImage else { return }
        uploadImageForUser(image: img, userID: photoId)
        
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
    }

    
    func verifyFace() {
        guard let image = capturedImage else {
            faceVerificationStatus = "No captured image to verify"
            return
        }
        
        FaceRecognitionManager.shared.encodeFace(from: image, for: "tempUser") { success, points in
            DispatchQueue.main.async {
                faceVerificationStatus = success ? "Face verification successful" : "Face verification failed"
            }
        }
    }
}
