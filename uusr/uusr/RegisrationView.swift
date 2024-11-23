//
//  Register.swift
//  uusr
//
//  Created by Jianming Chen on 2024-11-05.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct RegistrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var unitNumber: String = ""
    @State private var buildingName: String = ""
    @State private var password: String = ""
    @State private var showingImagePicker = false
    @State private var profileImage: Image? = nil
    @State private var isEmailInvalid = false
    @State private var capturedImage: UIImage?
    @State private var showingFaceCapture = false
    @State private var faceVerificationStatus: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                // Profile Image and Face Capture Section
                HStack(spacing: 20) {
                    // Profile Image Section
                    VStack {
                        if profileImage != nil {
                            profileImage?
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
                
                // First Name Field
                TextField("First Name", text: $firstName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Last Name Field
                TextField("Last Name", text: $lastName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Email Field
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
                
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Unit Number Field
                TextField("Unit Number", text: $unitNumber)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Building Name Field
                TextField("Building Name", text: $buildingName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Register Button
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
        }
    }
    
    func registerUser() {
        guard let faceImage = capturedImage else {
            faceVerificationStatus = "Please capture face image first"
            return
        }
        
        let db = Firestore.firestore()
        
        // Perform face encoding and save to Firebase
        FaceRecognitionManager.shared.encodeFace(from: faceImage, for: UUID().uuidString) { success, faceEncoding in
            DispatchQueue.main.async {
                if success, let faceEncoding = faceEncoding {
                    // Check if the face encoding already exists in the database
                    db.collection("users").whereField("faceEncoding", arrayContainsAny: faceEncoding.map { ["x": $0.x, "y": $0.y] }).getDocuments { snapshot, error in
                        if let error = error {
                            print("Error checking face encoding: \(error)")
                            faceVerificationStatus = "You already have an account, please sign in."
                        } else if let snapshot = snapshot, !snapshot.isEmpty {
                            // If a face encoding match is found, deny registration
                            faceVerificationStatus = "Face already registered. Cannot register again with the same face."
                        } else {
                            // Proceed with registration if no duplicate face encoding is found
                            let newUser = User(
                                email: email,
                                password: password,
                                role: .individual,
                                firstName: firstName,
                                lastName: lastName,
                                unitNumber: unitNumber.isEmpty ? nil : unitNumber,
                                buildingName: buildingName.isEmpty ? nil : buildingName
                            )
                            
                            // Convert User instance to dictionary for Firestore
                            var userData: [String: Any] = [
                                "id": newUser.id.uuidString,
                                "firstName": newUser.firstName,
                                "lastName": newUser.lastName,
                                "email": newUser.email,
                                "password": newUser.password,
                                "unitNumber": newUser.unitNumber ?? "",
                                "buildingName": newUser.buildingName ?? "",
                                "role": newUser.role == .manager ? "manager" : "individual",
                                "status": Status.allCases.reduce(into: [String: Bool]()) { $0[$1.rawValue] = false },
                                "faceEncoding": faceEncoding.map { ["x": $0.x, "y": $0.y] }
                            ]
                            
                            db.collection("users").document(newUser.id.uuidString).setData(userData) { error in
                                if let error = error {
                                    print("Error adding document: \(error)")
                                    faceVerificationStatus = "Failed to register user"
                                } else {
                                    faceVerificationStatus = "User successfully registered with face data"
                                    saveFaceToStorage(faceImage: faceImage, userId: newUser.id.uuidString)
                                    // Close the page after successful registration
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                } else {
                    faceVerificationStatus = "Face encoding failed. Please try again."
                }
            }
        }
    }

    func saveFaceToStorage(faceImage: UIImage, userId: String) {
        if let imageData = faceImage.jpegData(compressionQuality: 0.8) {
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let imageRef = storageRef.child("faces/\(userId).jpg")
            
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading face image: \(error)")
                } else {
                    print("Face image successfully uploaded for user \(userId)")
                }
            }
        }
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
        
        FaceRecognitionManager.shared.encodeFace(from: image, for: email) { success, _ in
            DispatchQueue.main.async {
                if success {
                    faceVerificationStatus = "Face verification successful"
                } else {
                    faceVerificationStatus = "Face verification failed"
                }
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
