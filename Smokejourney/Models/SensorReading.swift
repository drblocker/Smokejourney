import SwiftData
import Foundation

@Model
final class SensorReading {
    var timestamp: Date?
    var temperature: Double?
    var humidity: Double?
    var sensor: Sensor?
    var sensorAsLastReading: Sensor?
    
    init(timestamp: Date = Date(), temperature: Double? = nil, humidity: Double? = nil) {
        self.timestamp = timestamp
        self.temperature = temperature
        self.humidity = humidity
    }
} 