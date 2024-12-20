import Foundation
import UIKit

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
    @Published var email: String
    @Published var password: String
    @Published var role: UserRole
    @Published var firstName: String
    @Published var lastName: String
    @Published var unitNumber: String?
    @Published var buildingName: String?
    @Published var statusDictionary: [String: Bool]
    @Published var faceImage: UIImage?
    @Published var faceEncoding: [CGPoint]? // Added faceEncoding to store face landmarks

    init(email: String, 
         password: String, 
         role: UserRole, 
         firstName: String, 
         lastName: String, 
         unitNumber: String?, 
         buildingName: String?, 
         statusDictionary: [String: Bool] = [:], 
         faceImage: UIImage? = nil, 
         faceEncoding: [CGPoint]? = nil) { // Added faceEncoding to initializer
        self.email = email
        self.password = password
        self.role = role
        self.firstName = firstName
        self.lastName = lastName
        self.unitNumber = unitNumber
        self.buildingName = buildingName
        self.statusDictionary = statusDictionary
        self.faceImage = faceImage
        self.faceEncoding = faceEncoding
    }
}
