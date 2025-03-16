import SwiftUI

struct ModelPicker: View {
    @StateObject private var viewModel = ModelPickerViewModel()
    @State private var selectedModel: Model?
    @State private var showingPreview = false
    @State private var showingShareView = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Your Avatar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 15) {
                        ForEach(viewModel.models) { model in
                            ModelPickerItem(model: model, isSelected: model.id == selectedModel?.id) {
                                selectedModel = model
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 150)
                }
                .padding(.vertical)
                
                if let selectedModel = selectedModel {
                    VStack(spacing: 20) {
                        Text("Selected: \(selectedModel.name)")
                            .font(.headline)
                        
                        Button(action: {
                            showingPreview = true
                        }) {
                            Text("View Avatar")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            showingShareView = true
                        }) {
                            Text("Share QR Code")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                } else {
                    Text("Select an avatar to view or share")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadModels()
            }
            .sheet(isPresented: $showingPreview) {
                if let model = selectedModel {
                    AvatarPreviewView(model: model)
                }
            }
            .sheet(isPresented: $showingShareView) {
                if let model = selectedModel {
                    ShareAvatarView(avatarID: model.id)
                }
            }
        }
    }
}

struct ModelPickerItem: View {
    let model: Model
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                if let image = model.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let entity = model.modelEntity {
                    // If we have a 3D entity but no thumbnail, show a placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "cube.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                } else {
                    // Fallback if no image or entity
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(model.name.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 100, height: 100)
                }
            }
            
            Text(model.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100)
        }
        .onTapGesture {
            onTap()
        }
    }
}

// Preview for ModelPicker
struct ModelPicker_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(nil) { selectedModel in
            let viewModel = ModelPickerViewModel.preview()
            return ModelPicker(viewModel: viewModel, selectedModel: selectedModel) { _ in }
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Model Picker")
        }
    }
}

// Helper for previews with @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
} 