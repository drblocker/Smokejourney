import Foundation
import HomeKit

// Protocol that unifies different sensor types
protocol EnvironmentalSensor: Identifiable {
    var id: String { get }
    var name: String { get }
    var type: SensorKit.SensorType { get }
    var lastUpdated: Date? { get }
    
    // Core readings
    var currentTemperature: Double? { get }  // Always in Fahrenheit
    var currentHumidity: Double? { get }     // Percentage
    
    // Data fetching
    func fetchCurrentReading() async throws
    func fetchHistoricalData(timeRange: TimeRange) async throws -> [SensorKit.SensorReading]
} 