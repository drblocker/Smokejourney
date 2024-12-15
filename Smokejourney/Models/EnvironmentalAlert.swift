import Foundation

enum EnvironmentalAlert: Identifiable {
    case temperatureLow(sensorId: String, value: Double)
    case temperatureHigh(sensorId: String, value: Double)
    case humidityLow(sensorId: String, value: Double)
    case humidityHigh(sensorId: String, value: Double)
    
    var id: String {
        switch self {
        case .temperatureLow(let id, _), 
             .temperatureHigh(let id, _),
             .humidityLow(let id, _),
             .humidityHigh(let id, _):
            return id
        }
    }
} 