import SwiftData
import Foundation
import os.log

@Model
final class Humidor {
    private static let logger = Logger(subsystem: "com.smokejourney", category: "Humidor")
    
    // MARK: - Properties
    var name: String?
    var capacity: Int?
    var notes: String?
    var humidorDescription: String?
    var location: String?
    var createdAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \Cigar.humidor) var cigars: [Cigar]?
    var sensorId: String?
    
    @Relationship(deleteRule: .cascade, inverse: \Sensor.humidor) var sensors: [Sensor]?
    @Relationship(deleteRule: .nullify, inverse: \ClimateSensor.humidor) var climateSensor: ClimateSensor?
    @Relationship(deleteRule: .cascade, inverse: \EnvironmentSettings.humidor) var environmentSettings: EnvironmentSettings?
    
    // MARK: - HomeKit Properties
    var homeKitEnabled: Bool = false
    var homeKitRoomName: String?
    var homeKitAccessoryIdentifier: String?
    var homeKitTemperatureSensorID: String?
    var homeKitHumiditySensorID: String?
    
    // MARK: - Constants
    private enum Constants {
        static let defaultCapacity = 25
        static let defaultName = "Unnamed Humidor"
        static let defaultDescription = "No description provided"
        static let capacityThreshold = 0.9
        static let defaultMaxTemp = 72.0
        static let defaultMinTemp = 65.0
        static let defaultMaxHumidity = 72.0
        static let defaultMinHumidity = 65.0
    }
    
    // MARK: - Initialization
    init(name: String, capacity: Int, description: String? = nil, location: String? = nil) {
        self.name = name
        self.capacity = capacity
        self.humidorDescription = description
        self.location = location
        self.createdAt = Date()
        self.cigars = []
    }
    
    convenience init() {
        self.init(
            name: Constants.defaultName,
            capacity: Constants.defaultCapacity
        )
    }
    
    // MARK: - Computed Properties
    var effectiveName: String {
        name ?? Constants.defaultName
    }
    
    var effectiveCapacity: Int {
        capacity ?? Constants.defaultCapacity
    }
    
    var effectiveDescription: String {
        humidorDescription ?? Constants.defaultDescription
    }
    
    var effectiveCigars: [Cigar] {
        cigars ?? []
    }
    
    var effectiveCreatedAt: Date {
        createdAt ?? Date()
    }
    
    var totalCigarCount: Int {
        effectiveCigars.reduce(0) { $0 + $1.totalQuantity }
    }
    
    var capacityPercentage: Double {
        Double(totalCigarCount) / Double(effectiveCapacity)
    }
    
    var isNearCapacity: Bool {
        capacityPercentage >= Constants.capacityThreshold
    }
    
    var effectiveMaxTemperature: Double {
        environmentSettings?.maxTemperature ?? Constants.defaultMaxTemp
    }
    
    var effectiveMinTemperature: Double {
        environmentSettings?.minTemperature ?? Constants.defaultMinTemp
    }
    
    var effectiveMaxHumidity: Double {
        environmentSettings?.maxHumidity ?? Constants.defaultMaxHumidity
    }
    
    var effectiveMinHumidity: Double {
        environmentSettings?.minHumidity ?? Constants.defaultMinHumidity
    }
    
    // Add HomeKit sensor identifiers
    var temperatureSensorID: String?
    var humiditySensorID: String?
    
    // Add computed properties for current readings
    @Transient var currentTemperature: Double?
    @Transient var currentHumidity: Double?
} 
