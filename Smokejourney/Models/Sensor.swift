import SwiftData
import Foundation

@Model
final class Sensor: Identifiable {
    var id: String?
    var name: String?
    var customName: String?
    var location: String?
    var type: SensorType?
    @Relationship(deleteRule: .cascade) var readings: [SensorReading]?
    @Relationship(deleteRule: .nullify) var humidor: Humidor?
    
    var displayName: String {
        customName ?? name ?? ""
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         type: SensorType,
         readings: [SensorReading] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.readings = readings
    }
}