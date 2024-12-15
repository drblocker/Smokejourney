import Foundation
import HomeKit
import SwiftUI
import os.log
import Combine

@MainActor
class SensorManager: ObservableObject {
    @Published private(set) var sensors: [any EnvironmentalSensor] = []
    @Published private(set) var readings: [String: SensorKit.SensorReading] = [:]
    
    init() { }
    
    func addSensor(_ sensor: any EnvironmentalSensor) {
        if !sensors.contains(where: { $0.id == sensor.id }) {
            sensors.append(sensor)
        }
    }
    
    func removeSensor(_ id: String) {
        sensors.removeAll { $0.id == id }
        readings.removeValue(forKey: id)
    }
    
    func updateReadings(for sensorId: String, with newReadings: [SensorKit.SensorReading]) {
        // Update the readings for this sensor
        if let latest = newReadings.last {
            readings[sensorId] = latest
        }
    }
} 