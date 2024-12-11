import SwiftData
import Foundation

@Model
final class SensorReading {
    var timestamp: Date?
    var value: Double?
    var type: ReadingType?
    var humidorPersistentID: String?
    
    var sensor: Sensor?
    
    init(timestamp: Date = Date(), value: Double, type: ReadingType, humidorPersistentID: String) {
        self.timestamp = timestamp
        self.value = value
        self.type = type
        self.humidorPersistentID = humidorPersistentID
    }
    
    enum ReadingType: Int, Codable {
        case temperature
        case humidity
    }
} 