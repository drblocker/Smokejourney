import SwiftData
import Foundation

@Model
final class Sensor {
    // MARK: - Properties
    var id: String?
    var name: String?
    var type: SensorType?
    var customName: String?
    var location: String?
    
    // MARK: - Relationships
    @Relationship(inverse: \Humidor.sensors)
    var humidor: Humidor?
    
    @Relationship(deleteRule: .cascade)
    var readings: [SensorReading]?
    
    var lastReading: SensorReading? {
        readings?.max(by: { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) })
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        customName ?? name ?? "Unnamed Sensor"
    }
    
    // MARK: - Initialization
    init(id: String, name: String, type: SensorType) {
        self.id = id
        self.name = name
        self.type = type
        self.readings = []
    }
}