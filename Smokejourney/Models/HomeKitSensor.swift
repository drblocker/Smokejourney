import Foundation
import HomeKit

class HomeKitSensor: NSObject, EnvironmentalSensor {
    let id: String
    let name: String
    let type: SensorKit.SensorType = .homeKit
    private(set) var lastUpdated: Date?
    
    private(set) var currentTemperature: Double?
    private(set) var currentHumidity: Double?
    
    private let accessory: HMAccessory
    
    init(accessory: HMAccessory) {
        self.accessory = accessory
        self.id = accessory.uniqueIdentifier.uuidString
        self.name = accessory.name
        super.init()
    }
    
    func fetchCurrentReading() async throws {
        guard let tempChar = accessory.temperatureCharacteristic,
              let humidityChar = accessory.humidityCharacteristic else {
            throw SensorError.characteristicsNotFound
        }
        
        try await tempChar.readValue()
        try await humidityChar.readValue()
        
        if let temp = tempChar.value as? Double,
           let humidity = humidityChar.value as? Double {
            // Convert Celsius to Fahrenheit
            self.currentTemperature = temp * 9/5 + 32
            self.currentHumidity = humidity
            self.lastUpdated = Date()
        }
    }
    
    func fetchHistoricalData(timeRange: TimeRange) async throws -> [SensorKit.SensorReading] {
        // HomeKit doesn't provide historical data, so we'll just return current reading
        try await fetchCurrentReading()
        
        if let temp = currentTemperature,
           let humidity = currentHumidity {
            return [SensorKit.SensorReading(
                timestamp: lastUpdated ?? Date(),
                temperature: temp,
                humidity: humidity
            )]
        }
        return []
    }
}

// MARK: - HomeKit Extensions
extension HMAccessory {
    var temperatureCharacteristic: HMCharacteristic? {
        services.lazy
            .flatMap(\.characteristics)
            .first { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }
    }
    
    var humidityCharacteristic: HMCharacteristic? {
        services.lazy
            .flatMap(\.characteristics)
            .first { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }
    }
} 