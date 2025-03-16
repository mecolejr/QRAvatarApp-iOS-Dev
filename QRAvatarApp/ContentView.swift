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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let user = authService.user {
                Text("Email: \(user.email ?? "No email")")
                    .font(.headline)
            }
            
            Button(action: {
                authService.signOut()
            }) {
                Text("Sign Out")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 50)
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
        ContentView()
            .environmentObject(AuthService())
    }
}
