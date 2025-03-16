import SwiftUI
import RealityKit

struct AvatarPreviewView: View {
    let model: Model
    var onColorChanged: ((Color) -> Void)? = nil
    
    @State private var selectedColor: Color = .blue
    @State private var showingQRCode = false
    @State private var showingARView = false
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
            
            // Action buttons
            HStack(spacing: 15) {
                // AR View Button
                Button(action: {
                    showingARView = true
                }) {
                    HStack {
                        Image(systemName: "arkit")
                        Text("View in AR")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Share QR Code Button
                Button(action: {
                    showingQRCode = true
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Share QR")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Avatar Preview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingQRCode) {
            EnhancedQRCodeShareSheet(model: model)
        }
        .fullScreenCover(isPresented: $showingARView) {
            NavigationView {
                ARViewerView(model: model)
                    .navigationBarItems(leading: Button("Close") {
                        showingARView = false
                    })
            }
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

// MARK: - Previews

struct AvatarPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ModelPickerViewModel.preview()
        if let model = viewModel.models.first {
            AvatarPreviewView(model: model)
        }
    }
} 