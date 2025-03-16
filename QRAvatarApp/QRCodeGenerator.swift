import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    static func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
        
        // Get output CIImage
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale the image to the desired size
        let scale = size / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Convert to UIImage
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}

// SwiftUI extension to make it easier to use in views
extension Image {
    static func qrCode(from string: String, size: CGFloat = 200) -> Image? {
        if let uiImage = QRCodeGenerator.generateQRCode(from: string, size: size) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// A reusable QR code view component
struct QRCodeView: View {
    let content: String
    let size: CGFloat
    
    init(content: String, size: CGFloat = 200) {
        self.content = content
        self.size = size
    }
    
    var body: some View {
        if let qrCode = Image.qrCode(from: content, size: size) {
            qrCode
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
                .background(Color.white)
                .cornerRadius(10)
        } else {
            // Fallback if QR code generation fails
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Text("QR Generation Failed")
                        .font(.caption)
                        .foregroundColor(.red)
                )
        }
    }
} 