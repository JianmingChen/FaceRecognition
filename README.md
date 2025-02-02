# User Simple Selfie Register (UUSR)

A SwiftUI-based iOS application that implements facial recognition for user authentication and management. The app provides a secure and efficient way to manage client information with face-based login capabilities.

## Project Structure

```
uusr/
├── uusr/
│   ├── Views/
│   │   ├── ContentView.swift         # Main view controller
│   │   ├── LoginView.swift           # Login interface
│   │   ├── RegistrationView.swift    # User registration
│   │   ├── ClientListView.swift      # Client management list
│   │   ├── PersonalDetailView.swift  # Detailed client information
│   │   ├── HomePageView.swift        # Home dashboard
│   │   ├── FaceCaptureView.swift     # Face capture interface
│   ├── Models/
│   │   ├── UserModel.swift           # User data model
│   │   └── UserViewModel.swift       # User state management
│   ├── Utilities/
│   │   ├── ImagePicker.swift         # Image selection utility
│   │   └── FaceRecognitionManager.swift # Face recognition handling
```

## Features

### Authentication
- Email/Password login
- Face recognition authentication
- User registration with selfie capture

### Client Management
- Comprehensive client list view
- Advanced search and filtering capabilities
- Sort by:
  - First name
  - Last name
  - Unit number

### Status Tracking
- Real-time status updates
- Status categories:
  - Completed
  - Refused
  - Partial
  - Pending
- Automatic synchronization with Firestore

### Face Recognition
- Facial landmark detection
- Biometric authentication
- Secure face data storage

## Version Update
- **Version 1.0**: Initial release with login functionality, client list view, client detail view, status updates, and data caching.
- **Version 2.0**: Added face recognition functionality for enhanced client filtering and verification. Improved user experience and automated client verification process.

### Core Technologies
- SwiftUI
- Firebase/Firestore
- AVFoundation (Camera handling)
- UIKit integration

### Data Architecture
- Observable object pattern
- Real-time data synchronization
- Local data caching
- Secure credential storage

## Getting Started

### Prerequisites
- Xcode 13.0+
- iOS 15.0+
- CocoaPods or Swift Package Manager
- Firebase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/uusr.git
```

2. Install dependencies:
```bash
cd uusr
pod install  # If using CocoaPods
```

3. Open `uusr.xcworkspace` in Xcode

4. Configure Firebase:
   - Add your `GoogleService-Info.plist`
   - Initialize Firebase in your app delegate

5. Build and run the project

## Development Team

### Version 1.0
- Parker Chen (parkerchen1123@outlook.com)
- Jerry Zhang (zhangzhe941020@yahoo.com)
- Phil Teng (https://github.com/Phil-CST-BCIT)

### Version 2.0
- Parker Chen (parkerchen1123@outlook.com)
- Jerry Zhang (zhangzhe941020@yahoo.com)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Developed as part of the Bachelor of Science in Computer Science program at British Columbia Institute of Technology (BCIT).
