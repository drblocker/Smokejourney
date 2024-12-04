import SwiftData
import Foundation

// Add a new type to distinguish between purchases and consumption
enum PurchaseType: String {
    case purchase = "purchase"
    case smoke = "smoke"
    case gift = "gift"
}

@Model
final class CigarPurchase {
    var id: String?
    var quantity: Int?
    var price: Decimal?
    var date: Date?
    var vendor: String?
    var url: String?
    var notes: String?
    var cigar: Cigar?
    var type: String? // Will store the raw string of PurchaseType
    
    init(quantity: Int, price: Decimal?, vendor: String? = nil, url: String? = nil, notes: String? = nil, type: PurchaseType = .purchase) {
        self.id = UUID().uuidString
        self.quantity = quantity
        self.price = price
        self.date = Date()
        self.vendor = vendor
        self.url = url
        self.notes = notes
        self.type = type.rawValue
    }
    
    var effectiveQuantity: Int {
        quantity ?? 0
    }
    
    var effectivePrice: Decimal {
        price ?? 0.0
    }
    
    var pricePerCigar: Decimal {
        guard effectiveQuantity > 0 else { return 0 }
        return effectivePrice / Decimal(effectiveQuantity)
    }
    
    var purchaseType: PurchaseType {
        if let typeString = type {
            return PurchaseType(rawValue: typeString) ?? .purchase
        }
        return quantity ?? 0 > 0 ? .purchase : .smoke
    }
} 