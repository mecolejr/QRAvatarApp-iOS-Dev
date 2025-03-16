import SwiftUI
import RealityKit

struct AvatarPreviewView: View {
    let model: Model
    var onColorChanged: ((Color) -> Void)? = nil
    
    @State private var selectedColor: Color = .blue
    @State private var showingQRCode = false
    @State private var isCustomized = false
    
    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(model.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 3D Model Preview
            ZStack {
                if let modelEntity = model.modelEntity {
                    ModelPreview(modelEntity: modelEntity)
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    // Fallback if no model entity is available
                    Image(uiImage: model.thumbnailImage ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            
            // Color customization
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Customize")
                        .font(.headline)
                        .padding(.leading)
                    
                    Spacer()
                    
                    if isCustomized {
                        Button(action: {
                            // Reset to default color
                            resetToDefaultColor()
                        }) {
                            Text("Reset")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                    }
                }
                
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
                                updateModelColor(color)
                                isCustomized = true
                                
                                // Notify parent about color change
                                onColorChanged?(color)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Share QR Code Button
            Button(action: {
                showingQRCode = true
            }) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("Share via QR Code")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Avatar Preview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingQRCode) {
            QRCodeShareSheet(model: model)
        }
        .onAppear {
            // Check if there's a saved customization for this model
            if let savedColor = UserDefaults.standard.getCustomization(for: model.id) {
                // Convert UIColor to SwiftUI Color
                selectedColor = Color(savedColor)
                isCustomized = true
            }
        }
    }
    
    private func updateModelColor(_ color: Color) {
        // Update the model entity's material color
        if let modelEntity = model.modelEntity {
            // Convert SwiftUI Color to UIColor to RealityKit's Material
            let uiColor = UIColor(color)
            
            // Update all materials to the selected color
            if let model = modelEntity.model {
                for i in 0..<model.materials.count {
                    var material = SimpleMaterial()
                    material.color = .init(tint: uiColor)
                    material.metallic = 0.7
                    material.roughness = 0.3
                    modelEntity.model?.materials[i] = material
                }
            }
        }
    }
    
    private func resetToDefaultColor() {
        // Reset to default blue color
        selectedColor = .blue
        updateModelColor(.blue)
        isCustomized = false
        
        // Remove saved customization
        UserDefaults.standard.removeObject(forKey: "customization_\(model.id)")
        
        // Notify parent about color change
        onColorChanged?(.blue)
    }
}

struct QRCodeShareSheet: View {
    let model: Model
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var qrCodeImage: UIImage?
    
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
            if let qrCode = model.qrCode {
                let qrView = QRCodeView(content: qrCode, size: 250)
                    .padding()
                    .shadow(radius: 5)
                    .onAppear {
                        // Generate QR code image for sharing
                        qrCodeImage = generateQRCode(from: qrCode)
                    }
                
                qrView
            } else {
                QRCodeView(content: model.id, size: 250)
                    .padding()
                    .shadow(radius: 5)
                    .onAppear {
                        // Generate QR code image for sharing
                        qrCodeImage = generateQRCode(from: model.id)
                    }
            }
            
            // Model info
            Text("Avatar: \(model.name)")
                .font(.headline)
            
            Text("ID: \(model.id)")
                .font(.caption)
                .foregroundColor(.secondary)
            
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
            .padding(.bottom)
            
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
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// ShareSheet for sharing content
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

struct AvatarPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ModelPickerViewModel.preview()
        if let model = viewModel.models.first {
            AvatarPreviewView(model: model)
        }
    }
} 