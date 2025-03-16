import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle URL scheme for QR code deep links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Check if the URL uses our custom scheme
        if url.scheme == "qravatar" {
            // Parse the URL
            if let modelId = QRCodeManager.shared.parseQRCodeData(from: url.absoluteString) {
                // Post a notification that can be observed by views
                NotificationCenter.default.post(
                    name: Notification.Name("QRAvatarURLOpened"),
                    object: nil,
                    userInfo: ["modelId": modelId]
                )
                return true
            }
        }
        return false
    }
} 