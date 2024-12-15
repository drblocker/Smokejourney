import Foundation

enum SensorError: LocalizedError {
    // General sensor errors
    case notFound
    case characteristicsNotFound
    case readFailed
    case invalidData
    case unauthorized
    case invalidCredentials
    case networkError(Error)
    case invalidResponse
    
    // HomeKit specific errors
    case noPrimaryHome
    case authorizationFailed
    case noAccessory
    case noCharacteristic
    
    var errorDescription: String? {
        switch self {
        // General errors
        case .notFound:
            return "Sensor not found"
        case .characteristicsNotFound:
            return "Required sensor characteristics not found"
        case .readFailed:
            return "Failed to read sensor data"
        case .invalidData:
            return "Invalid sensor data"
        case .unauthorized:
            return "Not authorized. Please sign in"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
            
        // HomeKit specific errors
        case .noPrimaryHome:
            return "No primary home found"
        case .authorizationFailed:
            return "Failed to get HomeKit authorization"
        case .noAccessory:
            return "Accessory not found"
        case .noCharacteristic:
            return "Required characteristic not found"
        }
    }
} 