import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    // The callback to send scanned code back to SwiftUI
    var onCodeScanned: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = context.coordinator  // Set the coordinator as delegate
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // No dynamic updates needed for now
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // Coordinator to act as AVCaptureMetadataOutputObjectsDelegate
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            // Check if we have at least one metadata object
            if let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               metadataObj.type == .qr,
               let code = metadataObj.stringValue {
                // Found a QR code, call the completion handler
                parent.onCodeScanned(code)
                // Dismiss the scanner view
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// A simple UIViewController that sets up the camera and scanning
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    // We'll assign this from QRScannerView
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Setup capture session
        let session = AVCaptureSession()
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        session.addInput(videoInput)
        
        // Setup metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]  // look for QR codes
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        if let previewLayer = previewLayer {
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        captureSession = session
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start video capture when view appears
        captureSession?.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop video capture when view disappears
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adjust preview layer to fill screen
        previewLayer?.frame = view.bounds
    }
}

// A SwiftUI wrapper for the QR scanner with a cancel button
struct QRScannerViewWithOverlay: View {
    var onCodeScanned: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            QRScannerView(onCodeScanned: onCodeScanned)
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.7)))
                    .padding()
            }
        }
    }
} 