import SwiftUI

struct ModelPicker: View {
    @StateObject private var viewModel = ModelPickerViewModel()
    @State private var showingPreview = false
    @State private var showingShareView = false
    @State private var showingARView = false
    @State private var showingRecentModels = false
    @State private var showingScanner = false
    @State private var modelToShare: Model? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with title and scan button
                HStack {
                    Text("Select Your Avatar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingScanner = true
                    }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
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
                                        ModelPickerItem(
                                            model: model, 
                                            isSelected: model.id == viewModel.selectedModel?.id,
                                            onTap: {
                                                viewModel.selectModel(model)
                                            },
                                            onShare: {
                                                modelToShare = model
                                                showingShareView = true
                                            }
                                        )
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
                                ModelPickerItem(
                                    model: model, 
                                    isSelected: model.id == viewModel.selectedModel?.id,
                                    onTap: {
                                        viewModel.selectModel(model)
                                    },
                                    onShare: {
                                        modelToShare = model
                                        showingShareView = true
                                    }
                                )
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
                            modelToShare = selectedModel
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
                    VStack(spacing: 20) {
                        Text("Select an avatar to view or share")
                            .foregroundColor(.secondary)
                            .padding()
                        
                        // Scan QR Code Button
                        Button(action: {
                            showingScanner = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Scan QR Code")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
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
                if let model = modelToShare ?? viewModel.selectedModel {
                    EnhancedQRCodeShareSheet(model: model)
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView()
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
    let onShare: () -> Void
    
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
                
                // Quick share button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: onShare) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.purple)
                                .clipShape(Circle())
                        }
                        .padding(5)
                    }
                    
                    Spacer()
                }
                .frame(width: 100, height: 100)
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
        ModelPicker()
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