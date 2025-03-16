import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel = ModelPickerViewModel()
    @State private var isShowingScanner = false
    @State private var scannedAvatarID: String? = nil
    @State private var showingPreview = false
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("QR Avatar App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // QR Code Scanning Button
                Button(action: {
                    isShowingScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title)
                        Text("Scan QR Code")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical)
                
                // Avatar Selection Section
                Text("Select Your Avatar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ModelPicker(viewModel: viewModel, selectedModel: $viewModel.selectedModel) { model in
                    viewModel.selectedModel = model
                    showingPreview = true
                }
                .frame(height: 200)
                
                if let selectedModel = viewModel.selectedModel {
                    VStack(spacing: 10) {
                        Text("Selected: \(selectedModel.name)")
                            .font(.headline)
                        
                        // Button to view avatar
                        Button(action: {
                            showingPreview = true
                        }) {
                            Text("View Avatar")
                                .font(.headline)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        // Button to share QR code
                        NavigationLink(destination: ShareAvatarView(avatarID: selectedModel.id)) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share QR Code")
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button(action: {
                    authService.signOut()
                }) {
                    HStack {
                        Text("Sign Out")
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            )
            .onAppear {
                viewModel.loadModels()
            }
            .sheet(isPresented: $isShowingScanner) {
                QRScannerViewWithOverlay { scannedCode in
                    self.scannedAvatarID = scannedCode
                    // After scanning, show the avatar preview
                    self.showingPreview = true
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let scannedID = scannedAvatarID {
                    // If we have a scanned ID, show that avatar
                    AvatarFromQRView(avatarID: scannedID)
                } else if let selectedModel = viewModel.selectedModel {
                    // Otherwise show the selected model
                    AvatarPreviewView(model: selectedModel)
                }
            }
        }
    }
}

// View for displaying an avatar from a scanned QR code
struct AvatarFromQRView: View {
    let avatarID: String
    @StateObject private var viewModel = ModelPickerViewModel()
    @State private var loadedModel: Model?
    
    var body: some View {
        VStack {
            if let model = loadedModel {
                AvatarPreviewView(model: model)
            } else {
                ProgressView("Loading avatar...")
                    .padding()
            }
        }
        .onAppear {
            // In a real app, this would fetch the avatar from a database
            // For now, we'll just find a model with matching ID or use the first one
            viewModel.loadModels()
            
            // Simulate a network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loadedModel = viewModel.models.first(where: { $0.id == avatarID }) ?? viewModel.models.first
            }
        }
    }
}

// View for sharing an avatar via QR code
struct ShareAvatarView: View {
    let avatarID: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Share Your Avatar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Let others scan this QR code to see your avatar")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            QRCodeView(content: avatarID, size: 250)
                .padding()
                .shadow(radius: 5)
            
            Text("Avatar ID: \(avatarID)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                // In a real app, this would share the QR code image
                // For now, it's just a placeholder
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share QR Code")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding()
        .navigationTitle("Share Avatar")
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard iPhone preview
            ContentView()
                .standardPreviewConfig(deviceName: "iPhone 14")
            
            // iPhone Pro Max preview
            ContentView()
                .standardPreviewConfig(deviceName: "iPhone 14 Pro Max")
            
            // iPad preview
            ContentView()
                .standardPreviewConfig(deviceName: "iPad Pro (11-inch)")
            
            // Landscape orientation preview
            DeviceOrientationPreviews {
                ContentView()
            }
            .standardPreviewConfig(deviceName: "iPhone 14 Pro")
            
            // Preview with pre-selected model
            previewWithSelectedModel
        }
    }
    
    // Extract the preview with selected model to a separate computed property
    static var previewWithSelectedModel: some View {
        let viewModel = ModelPickerViewModel()
        viewModel.loadModels()
        if !viewModel.models.isEmpty {
            viewModel.selectedModel = viewModel.models.first
        }
        
        return ContentView()
            .environmentObject(viewModel)
            .standardPreviewConfig(deviceName: "iPhone 14")
            .previewDisplayName("With Selected Model")
    }
}
