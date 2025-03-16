import SwiftUI

struct ModelPicker: View {
    @StateObject private var viewModel = ModelPickerViewModel()
    @State private var showingPreview = false
    @State private var showingShareView = false
    @State private var showingARView = false
    @State private var showingRecentModels = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Your Avatar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                // Recently viewed models section
                if !viewModel.recentlyViewedModels.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Recently Viewed")
                                .font(.headline)
                                .padding(.leading)
                            
                            Spacer()
                            
                            Button(action: {
                                showingRecentModels.toggle()
                            }) {
                                Text(showingRecentModels ? "Hide" : "Show")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing)
                        }
                        
                        if showingRecentModels {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 15) {
                                    ForEach(viewModel.recentlyViewedModels) { model in
                                        ModelPickerItem(model: model, isSelected: model.id == viewModel.selectedModel?.id) {
                                            viewModel.selectModel(model)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .frame(height: 150)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // All models section
                VStack(alignment: .leading) {
                    Text("All Avatars")
                        .font(.headline)
                        .padding(.leading)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(viewModel.models) { model in
                                ModelPickerItem(model: model, isSelected: model.id == viewModel.selectedModel?.id) {
                                    viewModel.selectModel(model)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(height: 150)
                    }
                    .padding(.vertical, 5)
                }
                .padding(.top, 10)
                
                if let selectedModel = viewModel.selectedModel {
                    VStack(spacing: 20) {
                        Text("Selected: \(selectedModel.name)")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            // View Avatar Button
                            Button(action: {
                                showingPreview = true
                                // Add to recently viewed when previewing
                                viewModel.addToRecentlyViewed(model: selectedModel)
                            }) {
                                HStack {
                                    Image(systemName: "eye")
                                    Text("View")
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            
                            // AR View Button
                            Button(action: {
                                showingARView = true
                                // Add to recently viewed when using AR
                                viewModel.addToRecentlyViewed(model: selectedModel)
                            }) {
                                HStack {
                                    Image(systemName: "arkit")
                                    Text("AR")
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Share QR Code Button
                        Button(action: {
                            showingShareView = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Share QR Code")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
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
                if let model = viewModel.selectedModel {
                    AvatarPreviewView(model: model, onColorChanged: { color in
                        // Save color customization when changed
                        viewModel.saveModelCustomization(model: model, color: UIColor(color))
                    })
                }
            }
            .sheet(isPresented: $showingShareView) {
                if let model = viewModel.selectedModel {
                    ShareAvatarView(avatarID: model.id)
                }
            }
            .fullScreenCover(isPresented: $showingARView) {
                if let model = viewModel.selectedModel {
                    NavigationView {
                        ARViewerView(model: model)
                            .navigationBarItems(leading: Button("Close") {
                                showingARView = false
                            })
                    }
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