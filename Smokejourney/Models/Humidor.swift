import SwiftData
import Foundation
import os.log

@Model
final class Humidor {
    private static let logger = Logger(subsystem: "com.smokejourney", category: "Humidor")
    
    var name: String?
    var capacity: Int?
    var humidorDescription: String?
    var location: String?
    var createdAt: Date?
    var cigars: [Cigar]?
    var sensorId: String?
    
    @Relationship(.cascade)
    var sensors: [Sensor]?
    
    var targetHumidity: Double?
    var targetTemperature: Double?
    
    // HomeKit properties
    var homeKitEnabled: Bool = false
    var homeKitRoomName: String?
    var homeKitAccessoryIdentifier: String?
    var homeKitTemperatureSensorID: String?
    var homeKitHumiditySensorID: String?
    
    @Relationship(deleteRule: .cascade)
    var environmentSettings: EnvironmentSettings?
    
    init(name: String, capacity: Int, description: String? = nil, location: String? = nil) {
        self.name = name
        self.capacity = capacity
        self.humidorDescription = description
        self.location = location
        self.createdAt = Date()
        self.cigars = []
        self.sensorId = nil
    }
    
    init() {
        self.createdAt = Date()
        self.cigars = []
        self.capacity = 25  // Default capacity
    }
    
    // MARK: - Computed Properties
    var effectiveName: String {
        name ?? "Unnamed Humidor"
    }
    
    var effectiveCapacity: Int {
        capacity ?? 25
    }
    
    var effectiveDescription: String {
        humidorDescription ?? "No description provided"
    }
    
    var effectiveCigars: [Cigar] {
        cigars ?? []
    }
    
    var effectiveCreatedAt: Date {
        createdAt ?? Date()
    }
    
    var totalCigarCount: Int {
        cigars?.reduce(into: 0) { total, cigar in
            total += cigar.totalQuantity
        } ?? 0
    }
    
    var capacityPercentage: Double {
        Double(totalCigarCount) / Double(effectiveCapacity)
    }
    
    var isNearCapacity: Bool {
        capacityPercentage >= 0.9 // 90% full
    }
    
    var effectiveMaxTemperature: Double {
        environmentSettings?.maxTemperature ?? 72.0
    }
    
    var effectiveMinTemperature: Double {
        environmentSettings?.minTemperature ?? 65.0
    }
    
    var effectiveMaxHumidity: Double {
        environmentSettings?.maxHumidity ?? 72.0
    }
    
    var effectiveMinHumidity: Double {
        environmentSettings?.minHumidity ?? 65.0
    }
} 
