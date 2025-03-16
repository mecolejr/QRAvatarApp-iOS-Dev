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
        static let arPlacements = "arPlacements"
        static let arSettings = "arSettings"
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
    
    // MARK: - AR Placements
    
    /// Save AR placement data for a specific model
    /// - Parameters:
    ///   - modelId: The ID of the model
    ///   - placements: Array of placement data (position, rotation, scale)
    func saveARPlacements(for modelId: String, placements: [[String: Any]]) {
        var allPlacements = dictionary(forKey: Keys.arPlacements) as? [String: [[String: Any]]] ?? [:]
        allPlacements[modelId] = placements
        set(allPlacements, forKey: Keys.arPlacements)
    }
    
    /// Get AR placement data for a specific model
    /// - Parameter modelId: The ID of the model
    /// - Returns: Array of placement data (position, rotation, scale)
    func getARPlacements(for modelId: String) -> [[String: Any]]? {
        guard let allPlacements = dictionary(forKey: Keys.arPlacements) as? [String: [[String: Any]]] else {
            return nil
        }
        return allPlacements[modelId]
    }
    
    /// Clear AR placements for a specific model
    /// - Parameter modelId: The ID of the model
    func clearARPlacements(for modelId: String) {
        var allPlacements = dictionary(forKey: Keys.arPlacements) as? [String: [[String: Any]]] ?? [:]
        allPlacements.removeValue(forKey: modelId)
        set(allPlacements, forKey: Keys.arPlacements)
    }
    
    /// Clear all AR placements
    func clearAllARPlacements() {
        removeObject(forKey: Keys.arPlacements)
    }
    
    // MARK: - AR Settings
    
    /// Save AR settings
    /// - Parameter settings: Dictionary of AR settings
    func saveARSettings(_ settings: [String: Any]) {
        set(settings, forKey: Keys.arSettings)
    }
    
    /// Get AR settings
    /// - Returns: Dictionary of AR settings
    func getARSettings() -> [String: Any]? {
        return dictionary(forKey: Keys.arSettings)
    }
    
    /// Update a specific AR setting
    /// - Parameters:
    ///   - key: Setting key
    ///   - value: Setting value
    func updateARSetting(key: String, value: Any) {
        var settings = getARSettings() ?? [:]
        settings[key] = value
        saveARSettings(settings)
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
        removeObject(forKey: Keys.arPlacements)
        removeObject(forKey: Keys.arSettings)
    }
} 