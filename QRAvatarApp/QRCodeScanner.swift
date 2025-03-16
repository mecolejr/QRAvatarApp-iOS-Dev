import SwiftUI
import AVFoundation
import UIKit

// QR Code Scanner View
struct QRCodeScannerView: View {
    @StateObject private var viewModel = ModelPickerViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @State private var scannedModel: Model?
    @State private var showingPreview = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Scanner view
                QRScannerRepresentable(
                    isScanning: $isScanning,
                    scannedCode: { code in
                        handleScannedCode(code)
                    }
                )
                .edgesIgnoringSafeArea(.all)
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 250, height: 250)
                        
                        // Scanning animation
                        if isScanning {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 2)
                                .offset(y: -125)
                                .animation(
                                    Animation.linear(duration: 2.5)
                                        .repeatForever(autoreverses: true),
                                    value: isScanning
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 20) {
                        Text("Scan QR Code")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Point your camera at a QR Avatar code")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
            .onAppear {
                isScanning = true
                viewModel.loadModels()
            }
            .onDisappear {
                isScanning = false
            }
            .sheet(isPresented: $showingPreview) {
                if let model = scannedModel {
                    AvatarPreviewView(model: model)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("QR Code Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Stop scanning
        isScanning = false
        
        // Parse the QR code
        if let modelId = QRCodeManager.shared.parseQRCodeData(from: code) {
            // Find the model with this ID
            if let model = viewModel.models.first(where: { $0.id == modelId }) {
                // Found the model
                scannedModel = model
                viewModel.selectModel(model)
                viewModel.addToRecentlyViewed(model: model)
                
                // Show preview
                showingPreview = true
            } else {
                // Model not found
                alertMessage = "Avatar not found. It may not be available in your library."
                showingAlert = true
            }
        } else {
            // Invalid QR code
            alertMessage = "Invalid QR code. Please scan a valid QR Avatar code."
            showingAlert = true
        }
        
        // Resume scanning after a delay if no model was found
        if scannedModel == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isScanning = true
            }
        }
    }
}

// UIKit wrapper for AVFoundation QR scanner
struct QRScannerRepresentable: UIViewRepresentable {
    @Binding var isScanning: Bool
    var scannedCode: (String) -> Void
    
    func makeUIView(context: Context) -> QRScannerView {
        let scannerView = QRScannerView()
        scannerView.delegate = context.coordinator
        return scannerView
    }
    
    func updateUIView(_ uiView: QRScannerView, context: Context) {
        if isScanning {
            uiView.startScanning()
        } else {
            uiView.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerViewDelegate {
        var parent: QRScannerRepresentable
        
        init(_ parent: QRScannerRepresentable) {
            self.parent = parent
        }
        
        func qrScanningDidFail() {
            // Handle failure
        }
        
        func qrScanningSucceededWithCode(_ code: String) {
            parent.scannedCode(code)
        }
        
        func qrScanningDidStop() {
            // Handle stop
        }
    }
}

// Protocol for QR scanner delegate
protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ code: String)
    func qrScanningDidStop()
}

// UIKit view for QR scanning
class QRScannerView: UIView {
    weak var delegate: QRScannerViewDelegate?
    
    // Capture session
    var captureSession: AVCaptureSession?
    
    // Init methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCaptureSession()
    }
    
    // Setup capture session
    private func setupCaptureSession() {
        // Create capture session
        let session = AVCaptureSession()
        
        // Get video capture device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.qrScanningDidFail()
            return
        }
        
        // Create input
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.qrScanningDidFail()
            return
        }
        
        // Add input to session
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            delegate?.qrScanningDidFail()
            return
        }
        
        // Create metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        // Add output to session
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            // Set delegate and use main queue
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrScanningDidFail()
            return
        }
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        // Store session
        captureSession = session
    }
    
    // Start scanning
    func startScanning() {
        if let captureSession = captureSession, !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        }
    }
    
    // Stop scanning
    func stopScanning() {
        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
            delegate?.qrScanningDidStop()
        }
    }
    
    // Layout subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = layer.bounds
        }
    }
}

// AVCaptureMetadataOutputObjectsDelegate
extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if we have at least one object
        if let metadataObject = metadataObjects.first {
            // Check if it's a QR code
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Notify delegate
            delegate?.qrScanningSucceededWithCode(stringValue)
        }
    }
} 