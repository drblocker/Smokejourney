import SwiftData
import Foundation
import SensorKit

@Model
final class ClimateSensor {
    var id: String?
    var name: String?
    var typeRawValue: String?
    @Relationship(deleteRule: .cascade) var readings: [SensorReading]?
    @Relationship(deleteRule: .nullify) var humidor: Humidor?
    
    var type: SensorKit.SensorType {
        get {
            SensorKit.SensorType(rawValue: typeRawValue ?? "") ?? .homeKit
        }
        set {
            typeRawValue = newValue.rawValue
        }
    }
    
    var currentTemperature: Double? {
        readings?.last?.temperature
    }
    
    var currentHumidity: Double? {
        readings?.last?.humidity
    }
    
    init(id: String = UUID().uuidString, name: String, type: SensorKit.SensorType) {
        self.id = id
        self.name = name
        self.typeRawValue = type.rawValue
        self.readings = []
    }
}