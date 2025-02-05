import SwiftUI

enum UserRole {
    case manager
    case individual
}

enum Status: String, CaseIterable {
    case completed
    case refused
    case partial
    case pending
}

class User: ObservableObject, Identifiable {
    let id = UUID()
    @Published var firestoreDocumentID: String
    @Published var email: String
    @Published var password: String
    @Published var role: UserRole
    @Published var firstName: String
    @Published var lastName: String
    @Published var unitNumber: String?
    @Published var buildingName: String?
    @Published var statusDictionary: [String: Bool]
    @Published var photo: UIImage?
    
    init(firestoreDocumentID: String = "",
         email: String,
         password: String,
         role: UserRole,
         firstName: String,
         lastName: String,
         unitNumber: String? = nil,
         buildingName: String? = nil,
         statusDictionary: [String: Bool] = [:]) {
        self.firestoreDocumentID = firestoreDocumentID
        self.email = email
        self.password = password
        self.role = role
        self.firstName = firstName
        self.lastName = lastName
        self.unitNumber = unitNumber
        self.buildingName = buildingName
        self.statusDictionary = statusDictionary
        print("trying to get image")
        let photoId = email.replacingOccurrences(of: ".com", with: "").replacingOccurrences(of: "@", with: "")
        downloadImage(filename: photoId) { img in
                    DispatchQueue.main.async {
                        self.photo = img
                        print("Got image")
                        print(self.photo)
                    }
                }
    }
    
    
}

