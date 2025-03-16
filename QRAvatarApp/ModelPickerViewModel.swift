import SwiftUI
import RealityKit
import Combine

class ModelPickerViewModel: ObservableObject {
    @Published var models: [Model] = []
    @Published var selectedModel: Model?
    @Published var recentlyViewedModels: [Model] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // Initialize and load models
    init() {
        loadModels()
    }
    
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
        
        // Load the last selected model from UserDefaults
        if let lastSelectedModelId = userDefaults.getLastSelectedModelId(),
           let lastModel = models.first(where: { $0.id == lastSelectedModelId }) {
            selectedModel = lastModel
        } else if selectedModel == nil && !models.isEmpty {
            // Select the first model by default if none is selected
            selectedModel = models.first
        }
        
        // Load recently viewed models
        loadRecentlyViewedModels()
        
        // Apply saved customizations to models
        applyCustomizations()
        
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
                if #available(iOS 18.0, *) {
                    entity = ModelEntity(mesh: .generateCylinder(height: 0.5, radius: 0.25))
                } else {
                    // Fallback for iOS 16/17
                    entity = ModelEntity(mesh: .generateBox(size: [0.5, 0.5, 0.5]))
                }
                entity.model?.materials = [SimpleMaterial(color: .orange, isMetallic: true)]
            case 3:
                // Capsule (using sphere for compatibility)
                entity = ModelEntity(mesh: .generateSphere(radius: 0.25))
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
    
    // Get a model by ID (for deep link handling)
    func getModelById(_ id: String) -> Model? {
        // Make sure models are loaded
        if models.isEmpty {
            loadModels()
        }
        
        // Find the model with the given ID
        let model = models.first(where: { $0.id == id })
        
        // If found, add to recently viewed
        if let model = model {
            addToRecentlyViewed(model: model)
        }
        
        return model
    }
    
    // MARK: - UserDefaults Integration
    
    /// Save the selected model to UserDefaults
    func saveSelectedModel() {
        if let model = selectedModel {
            userDefaults.saveLastSelectedModel(id: model.id)
        }
    }
    
    /// Add a model to recently viewed and save to UserDefaults
    func addToRecentlyViewed(model: Model) {
        userDefaults.addToRecentlyViewed(modelId: model.id)
        loadRecentlyViewedModels()
    }
    
    /// Load recently viewed models from UserDefaults
    private func loadRecentlyViewedModels() {
        let recentIds = userDefaults.getRecentlyViewedModels()
        recentlyViewedModels = recentIds.compactMap { id in
            return models.first(where: { $0.id == id })
        }
    }
    
    /// Save a color customization for a model
    func saveModelCustomization(model: Model, color: UIColor) {
        userDefaults.saveCustomization(for: model.id, color: color)
    }
    
    /// Apply saved customizations to models
    private func applyCustomizations() {
        for i in 0..<models.count {
            if let modelEntity = models[i].modelEntity,
               let savedColor = userDefaults.getCustomization(for: models[i].id) {
                
                // Apply the saved color to the model entity
                if let model = modelEntity.model {
                    for j in 0..<model.materials.count {
                        var material = SimpleMaterial()
                        material.color = .init(tint: savedColor)
                        material.metallic = 0.7
                        material.roughness = 0.3
                        modelEntity.model?.materials[j] = material
                    }
                }
            }
        }
    }
    
    /// Update model selection and save to UserDefaults
    func selectModel(_ model: Model) {
        selectedModel = model
        saveSelectedModel()
        addToRecentlyViewed(model: model)
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