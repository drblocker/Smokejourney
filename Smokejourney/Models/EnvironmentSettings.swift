import SwiftData
import Foundation

@Model
final class EnvironmentSettings {
    var maxTemperature: Double = 72.0
    var minTemperature: Double = 65.0
    var maxHumidity: Double = 75.0
    var minHumidity: Double = 62.0
    var humidor: Humidor?
    
    init(maxTemperature: Double = 72.0,
         minTemperature: Double = 65.0,
         maxHumidity: Double = 75.0,
         minHumidity: Double = 62.0) {
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.maxHumidity = maxHumidity
        self.minHumidity = minHumidity
    }
} 