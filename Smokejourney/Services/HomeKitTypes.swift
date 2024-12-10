import Foundation
import HomeKit

// MARK: - Error Types
enum HomeKitError: LocalizedError {
    case notAuthorized
    case noHomeFound
    case noHomeSelected
    case accessoryNotFound
    case roomNotFound
    case setupFailed(String)
    case authorizationDenied
    case connectionLost
    case recoveryFailed
    case operationTimeout
    case syncFailed
    case characteristicNotFound
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HomeKit access not authorized"
        case .noHomeFound:
            return "No HomeKit home found"
        case .noHomeSelected:
            return "No HomeKit home selected"
        case .accessoryNotFound:
            return "Accessory not found"
        case .roomNotFound:
            return "Room not found"
        case .setupFailed(let message):
            return "Setup failed: \(message)"
        case .authorizationDenied:
            return "HomeKit access denied"
        case .connectionLost:
            return "HomeKit connection lost"
        case .recoveryFailed:
            return "Failed to recover HomeKit connection"
        case .operationTimeout:
            return "Operation timed out"
        case .syncFailed:
            return "Failed to sync with HomeKit"
        case .characteristicNotFound:
            return "Characteristic not found"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}

// MARK: - Automation Types
enum AutomationTrigger {
    enum TriggerType {
        case threshold(value: Double, comparison: NSComparisonPredicate.Operator)
        case time(DateComponents)
    }
    
    case temperature(TriggerType)
    case humidity(TriggerType)
    
    var name: String {
        switch self {
        case .temperature: return "Temperature Trigger"
        case .humidity: return "Humidity Trigger"
        }
    }
}

enum AutomationAction {
    enum ActionType {
        case notification(String)
        case setValue(Double, HMCharacteristic)
    }
    
    case alert(ActionType)
    case adjust(ActionType)
    
    var name: String {
        switch self {
        case .alert: return "Alert Action"
        case .adjust: return "Adjustment Action"
        }
    }
} 