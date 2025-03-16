import Foundation
import UIKit

// Extension to handle data persistence with UserDefaults
extension UserDefaults {
    // Keys for stored values
    private enum Keys {
        static let lastSelectedModelId = "lastSelectedModelId"
        static let userCustomizations = "userCustomizations"
        static let recentlyViewedModels = "recentlyViewedModels"
        static let appTheme = "appTheme"
        static let userPreferences = "userPreferences"
    }
    
    // MARK: - Selected Model
    
    /// Save the ID of the last selected model
    func saveLastSelectedModel(id: String) {
        set(id, forKey: Keys.lastSelectedModelId)
    }
    
    /// Get the ID of the last selected model
    func getLastSelectedModelId() -> String? {
        return string(forKey: Keys.lastSelectedModelId)
    }
    
    // MARK: - Model Customizations
    
    /// Save color customization for a specific model
    func saveCustomization(for modelId: String, color: UIColor) {
        var customizations = dictionary(forKey: Keys.userCustomizations) as? [String: Data] ?? [:]
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            customizations[modelId] = colorData
            set(customizations, forKey: Keys.userCustomizations)
        }
    }
    
    /// Get color customization for a specific model
    func getCustomization(for modelId: String) -> UIColor? {
        guard let customizations = dictionary(forKey: Keys.userCustomizations) as? [String: Data],
              let colorData = customizations[modelId],
              let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor else {
            return nil
        }
        return color
    }
    
    // MARK: - Recently Viewed Models
    
    /// Add a model ID to recently viewed list
    func addToRecentlyViewed(modelId: String) {
        var recentlyViewed = array(forKey: Keys.recentlyViewedModels) as? [String] ?? []
        
        // Remove if already exists (to move it to the front)
        if let index = recentlyViewed.firstIndex(of: modelId) {
            recentlyViewed.remove(at: index)
        }
        
        // Add to the beginning of the array
        recentlyViewed.insert(modelId, at: 0)
        
        // Limit to 10 recent items
        if recentlyViewed.count > 10 {
            recentlyViewed = Array(recentlyViewed.prefix(10))
        }
        
        set(recentlyViewed, forKey: Keys.recentlyViewedModels)
    }
    
    /// Get list of recently viewed model IDs
    func getRecentlyViewedModels() -> [String] {
        return array(forKey: Keys.recentlyViewedModels) as? [String] ?? []
    }
    
    // MARK: - App Theme
    
    /// Save the app theme preference (light/dark/system)
    func saveAppTheme(_ theme: String) {
        set(theme, forKey: Keys.appTheme)
    }
    
    /// Get the app theme preference
    func getAppTheme() -> String {
        return string(forKey: Keys.appTheme) ?? "system"
    }
    
    // MARK: - User Preferences
    
    /// Save user preferences as a dictionary
    func saveUserPreferences(_ preferences: [String: Any]) {
        set(preferences, forKey: Keys.userPreferences)
    }
    
    /// Get user preferences
    func getUserPreferences() -> [String: Any]? {
        return dictionary(forKey: Keys.userPreferences)
    }
    
    /// Update a specific user preference
    func updateUserPreference(key: String, value: Any) {
        var preferences = getUserPreferences() ?? [:]
        preferences[key] = value
        saveUserPreferences(preferences)
    }
    
    // MARK: - Clear Data
    
    /// Clear all saved customizations
    func clearCustomizations() {
        removeObject(forKey: Keys.userCustomizations)
    }
    
    /// Clear recently viewed history
    func clearRecentlyViewed() {
        removeObject(forKey: Keys.recentlyViewedModels)
    }
    
    /// Reset all app preferences to defaults
    func resetAllPreferences() {
        removeObject(forKey: Keys.lastSelectedModelId)
        removeObject(forKey: Keys.userCustomizations)
        removeObject(forKey: Keys.recentlyViewedModels)
        removeObject(forKey: Keys.appTheme)
        removeObject(forKey: Keys.userPreferences)
    }
} 