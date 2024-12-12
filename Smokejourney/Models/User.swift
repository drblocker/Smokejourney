import SwiftData
import Foundation

@Model
final class User {
    // Required properties
    var id: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var profileImageData: Data?
    
    // Additional profile properties
    var memberSince: Date?
    var preferredTemperatureUnit: TemperatureUnit?
    var preferredHumidityUnit: HumidityUnit?
    var notificationsEnabled: Bool?
    var darkModeEnabled: Bool?
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    // Alias for fullName to maintain compatibility
    var name: String { fullName }
    
    init(id: String? = nil, 
         email: String? = nil, 
         firstName: String? = nil, 
         lastName: String? = nil, 
         profileImageData: Data? = nil,
         memberSince: Date? = Date(),
         preferredTemperatureUnit: TemperatureUnit? = .fahrenheit,
         preferredHumidityUnit: HumidityUnit? = .percentage,
         notificationsEnabled: Bool? = true,
         darkModeEnabled: Bool? = false) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageData = profileImageData
        self.memberSince = memberSince
        self.preferredTemperatureUnit = preferredTemperatureUnit
        self.preferredHumidityUnit = preferredHumidityUnit
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
    }
}

enum TemperatureUnit: String, Codable {
    case celsius = "°C"
    case fahrenheit = "°F"
}

enum HumidityUnit: String, Codable {
    case percentage = "%"
    case gramsPerCubicMeter = "g/m³"
}