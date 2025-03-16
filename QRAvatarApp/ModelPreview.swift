import SwiftUI
import RealityKit
import ARKit

struct ModelPreview: UIViewRepresentable {
    var modelEntity: ModelEntity
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure for non-AR mode (for simulator compatibility)
        #if targetEnvironment(simulator)
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config, options: [])
        #else
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        #endif
        
        // Create an anchor and add the model entity
        let anchor = AnchorEntity(world: [0, 0, -1])
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        
        // Configure the scene
        arView.environment.lighting.intensityExponent = 2
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update the model entity if needed
        if let anchor = uiView.scene.anchors.first,
           let existingEntity = anchor.children.first as? ModelEntity {
            // Replace the existing entity with the new one
            existingEntity.removeFromParent()
            anchor.addChild(modelEntity)
        }
    }
}

// MARK: - Previews

struct ModelPreview_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simple box entity for preview
        let boxEntity = ModelEntity(mesh: .generateBox(size: 0.5))
        boxEntity.model?.materials = [SimpleMaterial(color: .blue, isMetallic: true)]
        
        return ModelPreview(modelEntity: boxEntity)
            .frame(height: 300)
            .previewLayout(.sizeThatFits)
    }
} 