import SwiftUI
import Firebase

@main
struct QRAvatarApp: App {
    // Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Your existing authService
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
