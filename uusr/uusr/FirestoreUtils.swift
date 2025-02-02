
//
//  Untitled.swift
//  uusr
//
//  Created by ZHANG ZHE on 2025-02-02.
//

import FirebaseFirestore

func fetchUserFromFirestore(userID: String, completion: @escaping (User?) -> Void) {
    let db = Firestore.firestore()
    db.collection("users").document(userID).getDocument { (document, error) in
        if let document = document, document.exists {
            let data = document.data()
            let user = User(
                firestoreDocumentID: document.documentID, // Assign Firestore document ID
                email: data?["email"] as? String ?? "",
                password: data?["password"] as? String ?? "",
                role: (data?["role"] as? String ?? "") == "Manager" ? .manager : .individual,
                firstName: data?["firstName"] as? String ?? "",
                lastName: data?["lastName"] as? String ?? "",
                unitNumber: data?["unitNumber"] as? String,
                buildingName: data?["buildingName"] as? String,
                statusDictionary: data?["status"] as? [String: Bool] ?? [:]
            )
            print("Fetched user ID: \(document.documentID)")
            completion(user)
        } else {
            print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
        }
    }
}

func updateStatusInFirestore(for user: User) {
    let db = Firestore.firestore()

    guard !user.firestoreDocumentID.isEmpty else {
        print("Error: User does not have a valid Firestore document ID")
        print("User details: \(user)")
        return
    }

    db.collection("users").document(user.firestoreDocumentID).updateData([
        "status": user.statusDictionary
    ]) { error in
        if let error = error {
            print("Error updating status for user \(user.firestoreDocumentID): \(error.localizedDescription)")
        } else {
            print("Status successfully updated for user: \(user.firestoreDocumentID)")
        }
    }
}
