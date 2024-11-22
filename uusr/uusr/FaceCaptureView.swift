import SwiftUI
import AVFoundation

struct FaceCaptureView: View {
    @Binding var capturedImage: UIImage?
    var onCapture: (Bool) -> Void
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var camera = CameraController()
    
    var body: some View {
        ZStack {
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
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

class CameraController: ObservableObject {
    var session: AVCaptureSession?
    private var output: AVCapturePhotoOutput?
    private var completion: ((UIImage?) -> Void)?
    
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
    
    private var captureDelegate: PhotoCaptureDelegate?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCapturePhotoOutput()
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            self.session = session
            self.output = output
            
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
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