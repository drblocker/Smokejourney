import SwiftData
import Foundation

@Model
final class Humidor {
    var name: String?
    var capacity: Int?
    var humidorDescription: String?
    var location: String?
    var createdAt: Date?
    var cigars: [Cigar]?
    var sensorId: String?
    
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
        effectiveCigars.reduce(into: 0) { total, cigar in
            total += cigar.totalQuantity
        }
    }
    
    var capacityPercentage: Double {
        Double(totalCigarCount) / Double(effectiveCapacity)
    }
    
    var isNearCapacity: Bool {
        capacityPercentage >= 0.9 // 90% full
    }
} 