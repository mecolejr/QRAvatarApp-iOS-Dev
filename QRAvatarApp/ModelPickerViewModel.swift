import SwiftUI
import RealityKit
import Combine

class ModelPickerViewModel: ObservableObject {
    @Published var models: [Model] = []
    @Published var selectedModel: Model?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadModels() {
        // Check if we're in the simulator
        if SimulatorEnvironment.isSimulator {
            // Load sample models for simulator
            models = createSampleModels(count: 6)
            
            // Create simple 3D model entities for the first few models
            loadModelEntities()
        } else {
            // In a real device, we would load actual models
            // For now, we'll use the same sample models
            models = createSampleModels(count: 6)
            
            // In a real app, we would load actual 3D models here
            // For example, from USDZ files in the app bundle
            loadModelEntities()
        }
        
        // Select the first model by default if none is selected
        if selectedModel == nil && !models.isEmpty {
            selectedModel = models.first
        }
        
        // Notify UI of changes
        objectWillChange.send()
    }
    
    private func createSampleModels(count: Int) -> [Model] {
        var sampleModels: [Model] = []
        
        // Create placeholder images with different colors
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, 
                                .systemPurple, .systemRed, .systemTeal]
        
        for i in 0..<count {
            let modelId = "model-\(i+1)"
            let modelName = "Avatar \(i+1)"
            let color = colors[i % colors.count]
            
            // Create a placeholder image with the color
            let thumbnailImage = createPlaceholderImage(color: color, text: String(i+1))
            
            // Create the model with a unique QR code
            let model = Model(
                id: modelId,
                name: modelName,
                thumbnailImage: thumbnailImage,
                qrCode: "qravatar://model/\(modelId)"
            )
            
            sampleModels.append(model)
        }
        
        return sampleModels
    }
    
    private func createPlaceholderImage(color: UIColor, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        return renderer.image { context in
            // Fill background with color
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            
            // Add text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (200 - textSize.width) / 2,
                y: (200 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func loadModelEntities() {
        // Create simple 3D model entities for the first few models
        // In a real app, you would load actual USDZ models
        
        // Only create entities for the first 4 models to avoid overloading memory
        let count = min(4, models.count)
        
        for i in 0..<count {
            // Create different primitive shapes for variety
            let entity: ModelEntity
            
            switch i % 4 {
            case 0:
                // Box
                entity = ModelEntity(mesh: .generateBox(size: 0.5))
                entity.model?.materials = [SimpleMaterial(color: .blue, isMetallic: true)]
            case 1:
                // Sphere
                entity = ModelEntity(mesh: .generateSphere(radius: 0.25))
                entity.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            case 2:
                // Cylinder
                entity = ModelEntity(mesh: .generateCylinder(height: 0.5, radius: 0.25))
                entity.model?.materials = [SimpleMaterial(color: .orange, isMetallic: true)]
            case 3:
                // Capsule
                entity = ModelEntity(mesh: .generateCapsule(height: 0.5, radius: 0.25))
                entity.model?.materials = [SimpleMaterial(color: .purple, isMetallic: false)]
            default:
                entity = ModelEntity(mesh: .generateBox(size: 0.5))
                entity.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
            }
            
            // Update the model with the entity
            models[i].modelEntity = entity
        }
    }
    
    // Helper method for finding a model by ID (useful for QR code scanning)
    func findModel(byId id: String) -> Model? {
        return models.first(where: { $0.id == id })
    }
    
    // Helper method for finding a model by QR code content
    func findModel(byQRCode qrCode: String) -> Model? {
        return models.first(where: { $0.qrCode == qrCode })
    }
    
    // MARK: - Preview Helpers
    
    static func preview() -> ModelPickerViewModel {
        let viewModel = ModelPickerViewModel()
        viewModel.loadModels()
        return viewModel
    }
    
    static func previewWithSelection() -> ModelPickerViewModel {
        let viewModel = ModelPickerViewModel()
        viewModel.loadModels()
        if !viewModel.models.isEmpty {
            viewModel.selectedModel = viewModel.models.first
        }
        return viewModel
    }
} 