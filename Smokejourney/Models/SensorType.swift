import Foundation

enum SensorType: Int, Codable {
    case temperature
    case humidity
    case combo
    
    var description: String {
        switch self {
        case .temperature: return "Temperature Only"
        case .humidity: return "Humidity Only"
        case .combo: return "Temperature & Humidity"
        }
    }
} 