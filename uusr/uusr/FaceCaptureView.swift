import SwiftUI
import AVFoundation
import Vision

enum FaceCaptureMode {
    case login
    case capture
}

struct FaceCaptureView: View {
    @Binding var capturedImage: UIImage?
    var mode: FaceCaptureMode
    var onFrameCaptured: ((UIImage) -> Void)?  // For login mode
    var onCapture: ((Bool) -> Void)?           // For capture mode
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var camera = CameraController()
    
    var body: some View {
        ZStack {
            if camera.isSetupComplete {
                CameraPreview(camera: camera)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    Text(camera.isFaceDetected ? "Face Detected" : "No Face Detected")
                        .foregroundColor(camera.isFaceDetected ? .green : .red)
                        .font(.title)
                        .padding()
                    
                    if mode == .capture {
                        Button(action: {
                            if let buffer = camera.latestBuffer {
                                let image = camera.imageBufferToUIImage(imageBuffer: buffer)
                                capturedImage = image
                                onCapture?(true)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Capture")
                                .padding()
                                .frame(width: 120)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 30)
                    }
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
            camera.mode = mode
            camera.onFaceImageCaptured = { image in
                if mode == .login {
                    capturedImage = image
                    onFrameCaptured?(image)
                }
            }
            camera.checkPermissions()
        }
        .onDisappear {
            camera.stopCamera()
        }
    }
}

class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isSetupComplete = false
    @Published var error: Error?
    @Published var isFaceDetected = false
    
    var latestBuffer: CVImageBuffer?
    var mode: FaceCaptureMode = .login
    var session: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var requestHandler: VNSequenceRequestHandler?
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    var onFaceImageCaptured: ((UIImage) -> Void)?  // 回调给 LoginView
    private var lastCaptureTime: Date = .distantPast  // 限频机制
    
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
            let output = AVCaptureVideoDataOutput()
            
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
                session.commitConfiguration()
                
                self.session = session
                self.output = output
                
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
                self.requestHandler = VNSequenceRequestHandler()
                
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

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            try requestHandler?.perform([faceDetectionRequest], on: imageBuffer)
            
            if let results = faceDetectionRequest.results, !results.isEmpty {
                DispatchQueue.main.async {
                    self.isFaceDetected = true
                }
                
                latestBuffer = imageBuffer

                // 防止过于频繁触发
                let now = Date()
                if now.timeIntervalSince(lastCaptureTime) > 1.5 {  // 限制每1.5秒最多1次识别
                    lastCaptureTime = now
                    if mode == .login {
                        let uiImage = imageBufferToUIImage(imageBuffer: imageBuffer)
                        DispatchQueue.main.async {
                            self.onFaceImageCaptured?(uiImage)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isFaceDetected = false
                }
            }
        } catch {
            print("Face detection error: \(error.localizedDescription)")
        }
    }

    func stopCamera() {
        session?.stopRunning()
        session = nil
    }

    func imageBufferToUIImage(imageBuffer: CVImageBuffer) -> UIImage {
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage()
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
