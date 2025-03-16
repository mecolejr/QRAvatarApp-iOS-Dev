import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

// QRCodeManager handles all QR code generation and customization
class QRCodeManager {
    // Singleton instance
    static let shared = QRCodeManager()
    
    private init() {}
    
    // MARK: - QR Code Generation
    
    /// Generate a basic QR code from a string
    /// - Parameters:
    ///   - string: Content to encode in the QR code
    ///   - correctionLevel: Error correction level (L, M, Q, H)
    ///   - size: Size of the QR code image
    /// - Returns: UIImage containing the QR code
    func generateQRCode(from string: String, correctionLevel: String = "M", size: CGFloat = 250) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = correctionLevel
        
        if let outputImage = filter.outputImage {
            // Scale the image
            let scale = size / outputImage.extent.width
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    /// Generate a styled QR code with logo and colors
    /// - Parameters:
    ///   - string: Content to encode in the QR code
    ///   - logo: Optional logo to place in the center
    ///   - primaryColor: Main color for QR code
    ///   - backgroundColor: Background color
    ///   - size: Size of the QR code image
    /// - Returns: UIImage containing the styled QR code
    func generateStyledQRCode(
        from string: String,
        logo: UIImage? = nil,
        primaryColor: UIColor = .black,
        backgroundColor: UIColor = .white,
        size: CGFloat = 250
    ) -> UIImage {
        // Generate basic QR code with high correction level to accommodate logo
        let basicQRCode = generateQRCode(from: string, correctionLevel: "H", size: size)
        
        // Start drawing
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return basicQRCode
        }
        
        // Draw background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        
        // Convert QR code to mask
        let ciImage = CIImage(image: basicQRCode)
        let filter = CIFilter.falseColor()
        filter.inputImage = ciImage
        filter.color0 = CIColor(color: .clear)
        filter.color1 = CIColor(color: primaryColor)
        
        if let outputImage = filter.outputImage,
           let coloredQRImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            // Draw colored QR code
            context.draw(coloredQRImage, in: CGRect(x: 0, y: 0, width: size, height: size))
            
            // Draw logo if provided
            if let logo = logo {
                let logoSize = size * 0.25
                let logoRect = CGRect(
                    x: (size - logoSize) / 2,
                    y: (size - logoSize) / 2,
                    width: logoSize,
                    height: logoSize
                )
                
                // Draw white background for logo
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: logoRect.insetBy(dx: -5, dy: -5))
                
                // Draw logo
                if let cgLogo = logo.cgImage {
                    context.draw(cgLogo, in: logoRect)
                }
            }
            
            // Get the final image
            if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
                return finalImage
            }
        }
        
        return basicQRCode
    }
    
    // MARK: - QR Code Data
    
    /// Create a QR code data URL for a model
    /// - Parameter model: The model to encode
    /// - Returns: A URL string that can be used to identify the model
    func createQRCodeData(for model: Model) -> String {
        // Create a URL with the app scheme and model ID
        return "qravatar://model/\(model.id)"
    }
    
    /// Parse a QR code data URL
    /// - Parameter urlString: The URL string from the QR code
    /// - Returns: The model ID if valid, nil otherwise
    func parseQRCodeData(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              url.scheme == "qravatar",
              url.host == "model",
              let modelId = url.pathComponents.last,
              !modelId.isEmpty else {
            return nil
        }
        
        return modelId
    }
    
    // MARK: - Sharing
    
    /// Share a QR code for a model
    /// - Parameters:
    ///   - model: The model to share
    ///   - viewController: The view controller to present the share sheet from
    func shareQRCode(for model: Model, from viewController: UIViewController) {
        // Generate QR code data
        let qrData = createQRCodeData(for: model)
        
        // Generate styled QR code
        let appLogo = UIImage(named: "AppIcon") // Use app icon as logo
        let primaryColor = UIColor(Color.blue) // Use app's primary color
        let qrCodeImage = generateStyledQRCode(
            from: qrData,
            logo: appLogo,
            primaryColor: primaryColor
        )
        
        // Create share text
        let shareText = "Check out my QR Avatar! Scan this code to view it in the app."
        
        // Create share sheet
        let activityViewController = UIActivityViewController(
            activityItems: [qrCodeImage, shareText],
            applicationActivities: nil
        )
        
        // Present share sheet
        viewController.present(activityViewController, animated: true)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Get the UIViewController associated with this view
    private func getUIViewController() -> UIViewController? {
        // Find the UIViewController representing this view
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.rootViewController
    }
    
    /// Share a QR code for a model
    func shareQRCode(for model: Model) {
        if let viewController = getUIViewController() {
            QRCodeManager.shared.shareQRCode(for: model, from: viewController)
        }
    }
}

// MARK: - QR Code View Components

/// A view that displays a QR code with optional styling
struct EnhancedQRCodeView: View {
    let content: String
    var size: CGFloat = 250
    var primaryColor: Color = .black
    var backgroundColor: Color = .white
    var logoImage: UIImage? = nil
    
    var body: some View {
        Image(uiImage: generateQRCode())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
    
    private func generateQRCode() -> UIImage {
        if logoImage != nil || primaryColor != .black || backgroundColor != .white {
            return QRCodeManager.shared.generateStyledQRCode(
                from: content,
                logo: logoImage,
                primaryColor: UIColor(primaryColor),
                backgroundColor: UIColor(backgroundColor),
                size: size
            )
        } else {
            return QRCodeManager.shared.generateQRCode(
                from: content,
                size: size
            )
        }
    }
}

/// A view for sharing a QR code with enhanced styling and options
struct EnhancedQRCodeShareSheet: View {
    let model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var qrCodeImage: UIImage?
    @State private var selectedColor: Color = .blue
    @State private var includeAppLogo: Bool = true
    
    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            Text("Share Your Avatar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Let others scan this QR code to see your avatar")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // QR Code
            let qrContent = QRCodeManager.shared.createQRCodeData(for: model)
            EnhancedQRCodeView(
                content: qrContent,
                size: 250,
                primaryColor: selectedColor,
                backgroundColor: .white,
                logoImage: includeAppLogo ? UIImage(named: "AppIcon") : nil
            )
            .padding()
            .shadow(radius: 5)
            .onAppear {
                // Generate QR code image for sharing
                qrCodeImage = QRCodeManager.shared.generateStyledQRCode(
                    from: qrContent,
                    logo: includeAppLogo ? UIImage(named: "AppIcon") : nil,
                    primaryColor: UIColor(selectedColor),
                    backgroundColor: .white,
                    size: 250
                )
            }
            .onChange(of: selectedColor) { newColor in
                // Update QR code image when color changes
                qrCodeImage = QRCodeManager.shared.generateStyledQRCode(
                    from: qrContent,
                    logo: includeAppLogo ? UIImage(named: "AppIcon") : nil,
                    primaryColor: UIColor(newColor),
                    backgroundColor: .white,
                    size: 250
                )
            }
            .onChange(of: includeAppLogo) { include in
                // Update QR code image when logo option changes
                qrCodeImage = QRCodeManager.shared.generateStyledQRCode(
                    from: qrContent,
                    logo: include ? UIImage(named: "AppIcon") : nil,
                    primaryColor: UIColor(selectedColor),
                    backgroundColor: .white,
                    size: 250
                )
            }
            
            // Customization options
            VStack(alignment: .leading, spacing: 10) {
                Text("Customize QR Code")
                    .font(.headline)
                    .padding(.leading)
                
                // Color selection
                HStack(spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(color == selectedColor ? Color.white : Color.clear, lineWidth: 3)
                            )
                            .shadow(color: color == selectedColor ? color.opacity(0.6) : Color.clear, radius: 5)
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
                .padding(.horizontal)
                
                // Logo toggle
                Toggle("Include App Logo", isOn: $includeAppLogo)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Model info
            Text("Avatar: \(model.name)")
                .font(.headline)
            
            Spacer()
            
            // Share button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share QR Code")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Close button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
        .sheet(isPresented: $showingShareSheet) {
            if let image = qrCodeImage {
                ShareSheet(items: [image, "Check out my QR Avatar! Scan this code to view it in the app."])
            }
        }
    }
} 