import Foundation
import SwiftData

@Model
final class SensorReading: Identifiable {
    var id: String?
    var timestamp: Date?
    var temperature: Double?
    var humidity: Double?
    @Relationship(deleteRule: .nullify) var sensor: Sensor?
    @Relationship(deleteRule: .nullify) var climateSensor: ClimateSensor?
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         temperature: Double,
         humidity: Double,
         sensor: Sensor? = nil,
         climateSensor: ClimateSensor? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.temperature = temperature
        self.humidity = humidity
        self.sensor = sensor
        self.climateSensor = climateSensor
    }
} 