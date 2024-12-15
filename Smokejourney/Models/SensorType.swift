import Foundation

enum SensorType: String, Codable {
    case homeKit
    case sensorPush
    case bluetooth
    
    var description: String {
        switch self {
        case .homeKit:
            return "HomeKit"
        case .sensorPush:
            return "SensorPush"
        case .bluetooth:
            return "Bluetooth"
        }
    }
    
    var icon: String {
        switch self {
        case .homeKit:
            return "homekit"
        case .sensorPush:
            return "sensor.fill"
        case .bluetooth:
            return "bluetooth"
        }
    }
}