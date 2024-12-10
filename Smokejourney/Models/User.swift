import SwiftData
import Foundation

@Model
final class User {
    // MARK: - Properties
    var id: String?
    var email: String?
    var name: String?
    
    // Dates with default values
    var createdAt: Date = Date()
    var lastSignInDate: Date = Date()
    
    // Store preferences as codable data
    @Attribute(.externalStorage)
    private var preferencesData: Data?
    
    var preferences: [String: String] {
        get {
            guard let data = preferencesData,
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            preferencesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Initialization
    init(id: String, email: String? = nil, name: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        // Dates are initialized with default values
        self.preferences = [:] // Initialize empty preferences
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
}

// MARK: - User Preferences
extension User {
    enum PreferenceKey: String, CaseIterable {
        case temperatureUnit
        case humidityNotificationsEnabled
        case temperatureNotificationsEnabled
        case defaultHumidorCapacity
        case theme
        
        var defaultValue: String {
            switch self {
            case .temperatureUnit: return "fahrenheit"
            case .humidityNotificationsEnabled: return "true"
            case .temperatureNotificationsEnabled: return "true"
            case .defaultHumidorCapacity: return "25"
            case .theme: return "system"
            }
        }
    }
    
    func getPreference(_ key: PreferenceKey) -> String {
        preferences[key.rawValue] ?? key.defaultValue
    }
    
    func setPreference(_ value: String, for key: PreferenceKey) {
        var currentPreferences = preferences
        currentPreferences[key.rawValue] = value
        preferences = currentPreferences
    }
}

// MARK: - Codable Conformance
extension User {
    enum CodingKeys: String, CodingKey {
        case id, email, name, createdAt, lastSignInDate, preferencesData
    }
}