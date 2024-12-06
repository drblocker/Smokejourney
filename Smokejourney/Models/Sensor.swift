import SwiftData
import Foundation

@Model
final class Sensor {
    var id: String?
    var name: String?
    var type: SensorType?
    var customName: String?
    var location: String?
    var humidor: Humidor?
    @Relationship(inverse: \SensorReading.sensor) var readings: [SensorReading]?
    @Relationship(inverse: \SensorReading.sensorAsLastReading) var lastReading: SensorReading?
    
    var displayName: String {
        customName ?? name ?? "Unnamed Sensor"
    }
    
    init(id: String, name: String, type: SensorType) {
        self.id = id
        self.name = name
        self.type = type
    }
}