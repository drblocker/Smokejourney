import Foundation
import SwiftData

@Model
class ClimateSensor {
    var id: String
    var type: SensorType
    var addedAt: Date
    
    init(id: String, type: SensorType) {
        self.id = id
        self.type = type
        self.addedAt = Date()
    }
    
    enum SensorType: String, Codable {
        case sensorPush
        case homeKit
    }
} 