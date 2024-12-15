import Foundation

extension Smokejourney.EnvironmentalAlert {
    var title: String {
        switch self {
        case .temperatureLow: return "Low Temperature"
        case .temperatureHigh: return "High Temperature"
        case .humidityLow: return "Low Humidity"
        case .humidityHigh: return "High Humidity"
        }
    }
    
    var message: String {
        switch self {
        case .temperatureLow(_, let value):
            return String(format: "Temperature is too low (%.1f°F)", value)
        case .temperatureHigh(_, let value):
            return String(format: "Temperature is too high (%.1f°F)", value)
        case .humidityLow(_, let value):
            return String(format: "Humidity is too low (%.1f%%)", value)
        case .humidityHigh(_, let value):
            return String(format: "Humidity is too high (%.1f%%)", value)
        }
    }
} 