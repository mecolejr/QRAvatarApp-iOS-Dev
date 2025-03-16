import SwiftUI
import RealityKit

// MARK: - Simulator Preview Helpers

/// Helper struct to detect if we're running in a simulator
struct SimulatorEnvironment {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

/// Helper to create a simple 3D model for previews
struct PreviewModelFactory {
    /// Create a simple box model entity for previews
    static func createBoxEntity(color: UIColor = .blue, size: Float = 0.5) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    /// Create a simple sphere model entity for previews
    static func createSphereEntity(color: UIColor = .red, radius: Float = 0.25) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: true)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    /// Create a sample avatar model for previews
    static func createSampleAvatarEntity() -> ModelEntity {
        // Create a simple humanoid shape (head + body)
        let headMesh = MeshResource.generateSphere(radius: 0.15)
        let headMaterial = SimpleMaterial(color: .systemPink, roughness: 0.3, isMetallic: false)
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = [0, 0.3, 0]
        
        let bodyMesh = MeshResource.generateBox(size: [0.3, 0.5, 0.2])
        let bodyMaterial = SimpleMaterial(color: .systemBlue, roughness: 0.4, isMetallic: false)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        body.position = [0, -0.1, 0]
        
        // Create parent entity and add components
        let avatar = ModelEntity()
        avatar.addChild(head)
        avatar.addChild(body)
        
        return avatar
    }
    
    /// Create sample models for preview
    static func createSampleModels(count: Int = 4) -> [Model] {
        let models = (0..<count).map { index in
            let name = "Avatar \(index + 1)"
            let image = UIImage(systemName: "person.fill") ?? UIImage()
            
            // Create different entity types based on index
            let entity: ModelEntity
            switch index % 3 {
            case 0:
                entity = createBoxEntity(color: .systemBlue)
            case 1:
                entity = createSphereEntity(color: .systemRed)
            case 2:
                entity = createSampleAvatarEntity()
            default:
                entity = createBoxEntity()
            }
            
            return Model(name: name, previewImage: image, modelEntity: entity)
        }
        
        return models
    }
}

// MARK: - Preview Extensions

extension View {
    /// Apply common preview configurations for simulator
    func standardPreviewConfig(deviceName: String = "iPhone 14") -> some View {
        self
            .previewDevice(PreviewDevice(rawValue: deviceName))
            .previewDisplayName(deviceName)
    }
    
    /// Apply a preview layout with fixed dimensions
    func fixedPreviewSize(width: CGFloat, height: CGFloat) -> some View {
        self
            .previewLayout(.fixed(width: width, height: height))
    }
}

// MARK: - Preview Samples

/// Sample preview showing all device orientations
struct DeviceOrientationPreviews<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            content
                .previewDisplayName("Portrait")
            
            content
                .previewDisplayName("Landscape")
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
} 