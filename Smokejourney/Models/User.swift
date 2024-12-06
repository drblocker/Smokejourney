import SwiftData
import Foundation

@Model
final class User {
    var email: String?
    var displayName: String?
    var createdAt: Date?
    var lastSignInDate: Date?
    var appleUserIdentifier: String?
    var preferences: [String: String]?
    
    init() {
        self.createdAt = Date()
        self.lastSignInDate = Date()
        self.preferences = [:]
    }
    
    // MARK: - Computed Properties
    var effectiveName: String {
        displayName ?? email?.components(separatedBy: "@").first ?? "User"
    }
    
    var effectiveEmail: String {
        email ?? "No email provided"
    }
    
    var memberSince: String {
        createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }
    
    // MARK: - Helper Methods
    func updateLastSignIn() {
        self.lastSignInDate = Date()
    }
    
    func setPreference(_ value: String, forKey key: String) {
        var updatedPreferences = preferences ?? [:]
        updatedPreferences[key] = value
        preferences = updatedPreferences
    }
    
    func getPreference(forKey key: String) -> String? {
        preferences?[key]
    }
}

// MARK: - User Preferences Keys
extension User {
    enum PreferenceKey {
        static let temperatureUnit = "temperatureUnit"
        static let humidityNotificationsEnabled = "humidityNotificationsEnabled"
        static let temperatureNotificationsEnabled = "temperatureNotificationsEnabled"
        static let defaultHumidorCapacity = "defaultHumidorCapacity"
        static let theme = "theme"
    }
} 