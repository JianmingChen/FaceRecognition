import UIKit
import SwiftUI

class ViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    let userViewModel = UserViewModel()  // Create an instance of UserViewModel
    
    // Temporary test user accounts
    let testUsers = [
        User(email: "parker1123@outlook.com", password: "admin123", role: .manager, firstName: "Admin", lastName: "User", unitNumber: nil, buildingName: nil),
        User(email: "user@gmail.com", password: "user123", role: .individual, firstName: "User", lastName: "Person", unitNumber: nil, buildingName: nil)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentView = ContentView().environmentObject(userViewModel)
        let hostingController = UIHostingController(rootView: contentView)
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    @IBAction func signInTapped(_ sender: UIButton) {
        let email = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        print("Email entered: \(email), Password entered: \(password)")
        if email.isEmpty || password.isEmpty {
            showAlert(message: "Please enter both username and password.")
        } else {
            authenticateUser(username: email, password: password)
        }
    }
    
    func authenticateUser(username: String, password: String) {
        // Check if the entered username and password match any test user
        if let user = testUsers.first(where: { $0.email.lowercased() == username.lowercased() && $0.password == password }) {
            print("Login successful")
            userViewModel.isLoggedIn = true  // Update the state in UserViewModel
            
            // Navigate to different pages based on the user's role
            if user.role == .manager {
                navigateToHomePage()
            } else {
                navigateToPersonalDetailPage(user: user)
            }
        } else {
            print("No matching user found for email: \(username) and password: \(password)")
            showAlert(message: "Invalid username or password.")
        }
    }
    
    func navigateToHomePage() {
        let homePageView = HomePageView().environmentObject(userViewModel)
        let hostingController = UIHostingController(rootView: homePageView)
        present(hostingController, animated: true, completion: nil)
    }
    
    func navigateToPersonalDetailPage(user: User) {
        let personalDetailView = PersonalDetailView(user: user).environmentObject(userViewModel)
        let hostingController = UIHostingController(rootView: personalDetailView)
        present(hostingController, animated: true, completion: nil)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
