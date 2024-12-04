import SwiftData
import Foundation

@Model
final class Cigar {
    var brand: String?
    var name: String?
    var wrapperType: String?
    var size: String?
    var strength: CigarStrength?
    var createdAt: Date?
    var humidor: Humidor?
    var wrapperImageData: Data?
    @Relationship(deleteRule: .cascade) var purchases: [CigarPurchase]?
    @Relationship(deleteRule: .cascade) var reviews: [Review]?
    @Relationship(deleteRule: .cascade) var sessions: [SmokingSession]?
    
    init(brand: String, name: String, wrapperType: String, size: String, strength: CigarStrength) {
        self.brand = brand
        self.name = name
        self.wrapperType = wrapperType
        self.size = size
        self.strength = strength
        self.createdAt = Date()
        self.purchases = []
    }
    
    // Computed properties
    var totalQuantity: Int {
        (purchases ?? []).reduce(0) { $0 + $1.effectiveQuantity }
    }
    
    var totalCost: Decimal {
        (purchases ?? []).reduce(0) { $0 + $1.effectivePrice }
    }
    
    var averagePricePerCigar: Decimal {
        guard totalQuantity > 0 else { return 0 }
        return totalCost / Decimal(totalQuantity)
    }
    
    var purchaseHistory: [(date: Date, quantity: Int, price: Decimal)] {
        return (purchases ?? [])
            .compactMap { purchase in
                guard let date = purchase.date else { return nil }
                return (date, purchase.effectiveQuantity, purchase.effectivePrice)
            }
            .sorted { $0.date > $1.date }
    }
    
    var effectiveReviews: [Review] {
        reviews ?? []
    }
    
    var averageRating: Double {
        let validReviews = effectiveReviews.filter { $0.averageRating > 0 }
        guard !validReviews.isEmpty else { return 0 }
        return validReviews.reduce(0.0) { $0 + $1.averageRating } / Double(validReviews.count)
    }
}

enum CigarStrength: String, Codable {
    case mild
    case medium
    case full
} 