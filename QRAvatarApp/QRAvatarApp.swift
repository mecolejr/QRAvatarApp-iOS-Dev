import SwiftUI
import Firebase

@main
struct QRAvatarApp: App {
    // Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Your existing authService
    @StateObject private var authService = AuthService()
    
    // State for handling deep links
    @State private var deepLinkModelId: String? = nil
    @State private var showingDeepLinkModel = false
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .onAppear {
                        // Set up notification observer for QR code deep links
                        setupDeepLinkObserver()
                    }
                    .sheet(isPresented: $showingDeepLinkModel) {
                        if let modelId = deepLinkModelId,
                           let viewModel = ModelPickerViewModel(),
                           let model = viewModel.getModelById(modelId) {
                            AvatarPreviewView(model: model)
                        } else {
                            Text("Avatar not found")
                                .font(.headline)
                                .padding()
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
    
    // Set up observer for QR code deep links
    private func setupDeepLinkObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("QRAvatarURLOpened"),
            object: nil,
            queue: .main
        ) { notification in
            if let modelId = notification.userInfo?["modelId"] as? String {
                self.deepLinkModelId = modelId
                self.showingDeepLinkModel = true
            }
        }
    }
}
