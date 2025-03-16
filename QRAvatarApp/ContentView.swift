import SwiftUI
import RealityKit
import Firebase

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            // QR Scanner Tab
            QRScannerView()
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }
            
            // Model Picker Tab
            ModelPicker()
                .tabItem {
                    Label("Models", systemImage: "cube")
                }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSettings = false
    @State private var appTheme = UserDefaults.standard.getAppTheme()
    @State private var showRecentlyViewed = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    if let user = authService.user {
                        Text(user.email ?? "No email")
                            .font(.headline)
                    }
                }
                .padding(.top, 30)
                
                // Settings section
                List {
                    Section(header: Text("App Settings")) {
                        // Theme picker
                        Picker("App Theme", selection: $appTheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: appTheme) { newValue in
                            UserDefaults.standard.saveAppTheme(newValue)
                        }
                        
                        // Recently viewed toggle
                        Toggle("Show Recently Viewed", isOn: $showRecentlyViewed)
                            .onChange(of: showRecentlyViewed) { newValue in
                                UserDefaults.standard.updateUserPreference(key: "showRecentlyViewed", value: newValue)
                            }
                    }
                    
                    Section(header: Text("Data Management")) {
                        Button(action: {
                            UserDefaults.standard.clearRecentlyViewed()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear Recently Viewed")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Button(action: {
                            UserDefaults.standard.clearCustomizations()
                        }) {
                            HStack {
                                Image(systemName: "paintbrush")
                                    .foregroundColor(.orange)
                                Text("Reset All Customizations")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            authService.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Profile")
            .onAppear {
                // Load user preferences
                if let preferences = UserDefaults.standard.getUserPreferences() {
                    if let showRecent = preferences["showRecentlyViewed"] as? Bool {
                        showRecentlyViewed = showRecent
                    }
                } else {
                    // Initialize default preferences if none exist
                    let defaultPreferences: [String: Any] = [
                        "showRecentlyViewed": true
                    ]
                    UserDefaults.standard.saveUserPreferences(defaultPreferences)
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
                AvatarPreviewView(model: model, onColorChanged: { color in
                    // Save color customization when changed
                    viewModel.saveModelCustomization(model: model, color: UIColor(color))
                })
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
                
                // Add to recently viewed if found
                if let model = loadedModel {
                    viewModel.addToRecentlyViewed(model: model)
                }
            }
        }
    }
}

// View for sharing an avatar via QR code
struct ShareAvatarView: View {
    let avatarID: String
    @State private var showingShareSheet = false
    @State private var qrCodeImage: UIImage?
    
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
                .onAppear {
                    // Generate QR code image for sharing
                    qrCodeImage = generateQRCode(from: avatarID)
                }
            
            Text("Avatar ID: \(avatarID)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                showingShareSheet = true
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
        .sheet(isPresented: $showingShareSheet) {
            if let image = qrCodeImage {
                ShareSheet(items: [image, "Check out my QR Avatar! Scan this code to view it in the app."])
            }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// QR Code View
struct QRCodeView: View {
    let content: String
    let size: CGFloat
    
    var body: some View {
        Image(uiImage: generateQRCode(from: content))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
    }
}
