import SwiftData
import Foundation

@Model
final class User {
    // Required properties with default values
    var id: String = ""  // Will be set in init
    var createdAt: Date = Date()
    var lastSignInDate: Date = Date()
    var preferences: [String: String] = [:]
    
    // Optional properties
    var email: String?
    var name: String?
    
    init(id: String, email: String?, name: String?) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.lastSignInDate = Date()
        self.preferences = [:]
    }
    
    // MARK: - Computed Properties
    var effectiveName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        return email?.components(separatedBy: "@").first ?? "User"
    }
    
    var effectiveEmail: String {
        email ?? "No email provided"
    }
    
    var memberSince: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Helper Methods
    func updateLastSignIn() {
        self.lastSignInDate = Date()
    }
    
    func setPreference(_ value: String, forKey key: String) {
        preferences[key] = value
    }
    
    func getPreference(forKey key: String) -> String? {
        preferences[key]
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