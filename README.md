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
- Secure face data storage with CoreML model

### Client Management
- Comprehensive client list view
- Advanced search and filtering capabilities
- Sort by:
  - First name
  - Last name
  - Unit number
- Real-time client status updates
- Detailed client profiles with personal information

### Task Management
- Task creation and scheduling
- Multiple task types:
  - Medication reminders
  - Vitals check
  - House keeping
  - Exercise
  - Appointments
- Recurring task support
- Push notification reminders
- Task status tracking (Active/Disabled)
- YouTube video tutorials integration

### Face Recognition
- Facial landmark detection
- Biometric authentication
- Secure face data storage
- CoreML-based face embedding extraction
- Cosine similarity matching
- Real-time face verification

### Data Management
- Real-time Firestore synchronization
- Local data caching
- Secure credential storage
- File upload/download capabilities
- Profile photo management

## Version Update
- **Version 1.0**: Initial release with login functionality, client list view, client detail view, status updates, and data caching.
- **Version 2.0**: Added face recognition functionality for enhanced client filtering and verification. Improved user experience and automated client verification process.
- **Version 2.1**: Added comprehensive task management system with notifications, YouTube integration, and enhanced face recognition capabilities.

### Core Technologies
- SwiftUI
- Firebase/Firestore
- AVFoundation (Camera handling)
- UIKit integration
- CoreML for face recognition
- UserNotifications framework
- WebKit for video integration

### Data Architecture
- Observable object pattern
- Real-time data synchronization
- Local data caching
- Secure credential storage
- CoreML model integration
- Push notification system

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

### Version 3.0
- Jerry Zhang (zhangzhe941020@yahoo.com)
- skylerdev (Skyler2@mac.com)

### Version 4.0
- Jerry Zhang (zhangzhe941020@yahoo.com)


## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Developed as part of the Bachelor of Science in Computer Science program at British Columbia Institute of Technology (BCIT).
