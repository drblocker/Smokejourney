import SwiftData
import Foundation

@Model
final class User {
    // MARK: - Properties
    var email: String?
    var displayName: String?
    var createdAt: Date?
    var lastSignInDate: Date?
    var preferences: [String: String]?
    var appleUserIdentifier: String?
    
    // MARK: - Initialization
    init(email: String, displayName: String? = nil, appleUserIdentifier: String? = nil) {
        self.email = email
        self.displayName = displayName
        self.appleUserIdentifier = appleUserIdentifier
        self.createdAt = Date()
        self.lastSignInDate = Date()
        self.preferences = [:]
    }
    
    // MARK: - Computed Properties
    var effectiveName: String {
        displayName ?? email ?? "User"
    }
    
    var effectiveEmail: String {
        email ?? "No email provided"
    }
    
    var memberSince: String {
        createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }
    
    // MARK: - Helper Methods
    func updateLastSignIn() {
        lastSignInDate = Date()
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