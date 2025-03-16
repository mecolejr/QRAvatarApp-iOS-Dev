import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewerView: View {
    let model: Model
    @State private var isPlacementEnabled = true
    @State private var selectedAnchor: AnchorEntity?
    @State private var placedAnchors: [AnchorEntity] = []
    @State private var showingSettings = false
    @State private var modelScale: Float = 1.0
    @State private var showingHelp = true
    @State private var showingPlacementIndicator = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(
                model: model,
                isPlacementEnabled: $isPlacementEnabled,
                selectedAnchor: $selectedAnchor,
                placedAnchors: $placedAnchors,
                modelScale: $modelScale,
                showingPlacementIndicator: $showingPlacementIndicator
            )
            .edgesIgnoringSafeArea(.all)
            
            // Help overlay
            if showingHelp {
                VStack {
                    Text("Tap on a surface to place the avatar")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showingHelp)
                .onAppear {
                    // Auto-hide help after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            showingHelp = false
                        }
                    }
                }
            }
            
            // Bottom controls
            VStack(spacing: 20) {
                // Control buttons
                HStack(spacing: 30) {
                    // Reset button
                    Button(action: {
                        resetScene()
                    }) {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 22))
                            Text("Reset")
                                .font(.caption)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    }
                    
                    // Add avatar button
                    Button(action: {
                        isPlacementEnabled = true
                        showingPlacementIndicator = true
                        if !showingHelp {
                            withAnimation {
                                showingHelp = true
                                // Auto-hide help after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showingHelp = false
                                    }
                                }
                            }
                        }
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                            Text("Add")
                                .font(.caption)
                        }
                        .frame(width: 60, height: 60)
                        .background(isPlacementEnabled ? Color.green.opacity(0.8) : Color.white.opacity(0.8))
                        .foregroundColor(isPlacementEnabled ? .white : .blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    }
                    
                    // Settings button
                    Button(action: {
                        showingSettings = true
                    }) {
                        VStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 22))
                            Text("Settings")
                                .font(.caption)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("AR Viewer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSettings) {
            ARSettingsView(modelScale: $modelScale, selectedAnchor: $selectedAnchor)
        }
    }
    
    private func resetScene() {
        // Remove all placed anchors
        placedAnchors.removeAll()
        selectedAnchor = nil
        isPlacementEnabled = true
        showingPlacementIndicator = true
    }
}

struct ARViewContainer: UIViewRepresentable {
    let model: Model
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedAnchor: AnchorEntity?
    @Binding var placedAnchors: [AnchorEntity]
    @Binding var modelScale: Float
    @Binding var showingPlacementIndicator: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Set up coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Set up tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        // Set up long press gesture for selection
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        arView.addGestureRecognizer(longPressGesture)
        
        // Set up pinch gesture for scaling
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        arView.addGestureRecognizer(pinchGesture)
        
        // Set up rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation))
        arView.addGestureRecognizer(rotationGesture)
        
        // Add placement indicator
        if let modelEntity = model.modelEntity?.clone(recursive: true) {
            context.coordinator.placementIndicator = createPlacementIndicator()
            if showingPlacementIndicator {
                arView.scene.addAnchor(context.coordinator.placementIndicator)
            }
        }
        
        context.coordinator.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update placement indicator visibility
        if let placementIndicator = context.coordinator.placementIndicator {
            if showingPlacementIndicator && isPlacementEnabled {
                if !uiView.scene.anchors.contains(placementIndicator) {
                    uiView.scene.addAnchor(placementIndicator)
                }
            } else {
                if uiView.scene.anchors.contains(placementIndicator) {
                    placementIndicator.removeFromParent()
                }
            }
        }
        
        // Update model scale if selected
        if let selectedAnchor = selectedAnchor,
           let modelEntity = selectedAnchor.children.first as? ModelEntity {
            modelEntity.scale = [modelScale, modelScale, modelScale]
        }
        
        // Ensure all placed anchors are in the scene
        for anchor in placedAnchors {
            if !uiView.scene.anchors.contains(anchor) {
                uiView.scene.addAnchor(anchor)
            }
        }
        
        // Remove any anchors that are no longer in the placedAnchors array
        for anchor in uiView.scene.anchors {
            if anchor != context.coordinator.placementIndicator && !placedAnchors.contains(where: { $0 === anchor }) {
                anchor.removeFromParent()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createPlacementIndicator() -> AnchorEntity {
        let anchor = AnchorEntity(plane: .horizontal)
        
        // Create a semi-transparent circle to indicate placement
        let mesh = MeshResource.generatePlane(width: 0.5, depth: 0.5)
        let material = SimpleMaterial(color: .blue.withAlphaComponent(0.3), isMetallic: false)
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.name = "PlacementIndicator"
        
        // Rotate to lie flat on the ground
        planeEntity.transform.rotation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
        
        anchor.addChild(planeEntity)
        return anchor
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        var arView: ARView?
        var placementIndicator: AnchorEntity?
        var lastRotation: Float = 0
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView, parent.isPlacementEnabled else { return }
            
            let location = gesture.location(in: arView)
            
            // Perform hit test against detected planes
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            
            if let firstResult = results.first {
                // Create anchor at hit location
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                
                // Clone the model entity and add it to the anchor
                if let modelEntity = parent.model.modelEntity?.clone(recursive: true) {
                    // Apply current scale
                    modelEntity.scale = [parent.modelScale, parent.modelScale, parent.modelScale]
                    
                    // Add model to anchor
                    anchor.addChild(modelEntity)
                    
                    // Add anchor to scene
                    arView.scene.addAnchor(anchor)
                    
                    // Add to placed anchors
                    parent.placedAnchors.append(anchor)
                    
                    // Select the newly placed anchor
                    parent.selectedAnchor = anchor
                    
                    // Disable placement mode after placing
                    parent.isPlacementEnabled = false
                    parent.showingPlacementIndicator = false
                    
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let arView = arView, !parent.isPlacementEnabled else { return }
            
            if gesture.state == .began {
                let location = gesture.location(in: arView)
                
                // Check if we hit any placed models
                if let entity = arView.entity(at: location) as? ModelEntity,
                   let anchorEntity = entity.anchor {
                    // Select this anchor
                    parent.selectedAnchor = anchorEntity as? AnchorEntity
                    
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } else {
                    // Deselect if tapped elsewhere
                    parent.selectedAnchor = nil
                }
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let selectedAnchor = parent.selectedAnchor,
                  let modelEntity = selectedAnchor.children.first as? ModelEntity else { return }
            
            if gesture.state == .changed {
                // Update scale based on pinch
                let pinchScaleFactor = Float(gesture.scale)
                
                if gesture.scale > 1.0 {
                    // Scaling up
                    parent.modelScale *= min(pinchScaleFactor, 1.2)
                } else {
                    // Scaling down
                    parent.modelScale *= max(pinchScaleFactor, 0.8)
                }
                
                // Clamp scale to reasonable values
                parent.modelScale = min(max(parent.modelScale, 0.1), 5.0)
                
                // Reset gesture scale
                gesture.scale = 1.0
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let selectedAnchor = parent.selectedAnchor,
                  let modelEntity = selectedAnchor.children.first as? ModelEntity else { return }
            
            if gesture.state == .changed {
                // Get rotation in radians
                let rotation = Float(gesture.rotation)
                let rotationDelta = rotation - lastRotation
                
                // Apply rotation around y-axis (vertical)
                let currentTransform = modelEntity.transform
                modelEntity.transform = currentTransform.rotated(by: simd_quatf(angle: rotationDelta, axis: [0, 1, 0]))
                
                lastRotation = rotation
            }
            
            if gesture.state == .ended {
                lastRotation = 0
            }
        }
        
        // Update placement indicator position
        func updatePlacementIndicator() {
            guard let arView = arView, let placementIndicator = placementIndicator else { return }
            
            // Center of the screen
            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            
            // Perform raycast from center of screen
            let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
            
            if let firstResult = results.first {
                // Update placement indicator position
                placementIndicator.transform.matrix = firstResult.worldTransform
                
                // Make sure it's visible
                if !arView.scene.anchors.contains(placementIndicator) && parent.showingPlacementIndicator {
                    arView.scene.addAnchor(placementIndicator)
                }
            } else {
                // Hide if no plane detected
                if arView.scene.anchors.contains(placementIndicator) {
                    placementIndicator.removeFromParent()
                }
            }
        }
    }
}

struct ARSettingsView: View {
    @Binding var modelScale: Float
    @Binding var selectedAnchor: AnchorEntity?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model Settings")) {
                    VStack {
                        Text("Size: \(Int(modelScale * 100))%")
                        Slider(value: $modelScale, in: 0.1...5.0, step: 0.1)
                    }
                }
                
                Section {
                    if selectedAnchor != nil {
                        Button(action: {
                            // Delete selected model
                            if let selectedAnchor = selectedAnchor {
                                selectedAnchor.removeFromParent()
                                self.selectedAnchor = nil
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Delete Selected Avatar")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AR Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ARViewerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simple box entity for preview
        let boxEntity = ModelEntity(mesh: .generateBox(size: 0.5))
        boxEntity.model?.materials = [SimpleMaterial(color: .blue, isMetallic: true)]
        
        let model = Model(
            id: "preview-model",
            name: "Preview Model",
            modelEntity: boxEntity
        )
        
        return ARViewerView(model: model)
    }
} 