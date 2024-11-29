import SwiftUI
import AVFoundation

struct FaceCaptureView: View {
    @Binding var capturedImage: UIImage?
    var onCapture: (Bool) -> Void
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var camera = CameraController()
    
    var body: some View {
        ZStack {
            if camera.isSetupComplete {
                CameraPreview(camera: camera)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                        camera.capturePhoto { image in
                            capturedImage = image
                            onCapture(true)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .padding(.bottom, 30)
                }
            } else {
                if let error = camera.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ProgressView("Setting up camera...")
                }
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

class CameraController: ObservableObject {
    @Published var isSetupComplete = false
    @Published var error: Error?
    var session: AVCaptureSession?
    private var output: AVCapturePhotoOutput?
    private var completion: ((UIImage?) -> Void)?
    private var captureDelegate: PhotoCaptureDelegate?
    
    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        private let completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                completion(nil)
                return
            }
            completion(image)
        }
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.setupCamera()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self?.setupCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera access denied"])
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera access denied"])
            }
        }
    }
    
    private func setupCamera() {
        do {
            let session = AVCaptureSession()
            session.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No front camera available"])
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCapturePhotoOutput()
            
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
                session.commitConfiguration()
                
                self.session = session
                self.output = output
                
                DispatchQueue.main.async {
                    self.isSetupComplete = true
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let output = output else {
            completion(nil)
            return
        }
        
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        self.captureDelegate = PhotoCaptureDelegate(completion: completion)
        output.capturePhoto(with: settings, delegate: captureDelegate!)
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = camera.session
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
} 