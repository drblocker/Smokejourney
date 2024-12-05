import SwiftData
import Foundation

enum PurchaseType: String, Codable {
    case purchase = "purchase"
    case smoke = "smoke"
    case gift = "gift"
}

@Model
final class CigarPurchase {
    var quantity: Int?
    var price: Decimal?
    var date: Date?
    var vendor: String?
    var url: String?
    var notes: String?
    private var typeRawValue: String = PurchaseType.purchase.rawValue
    var cigar: Cigar?
    
    var type: PurchaseType {
        get {
            PurchaseType(rawValue: typeRawValue) ?? .purchase
        }
        set {
            typeRawValue = newValue.rawValue
        }
    }
    
    var effectiveQuantity: Int {
        switch type {
        case .purchase:
            return quantity ?? 0
        case .smoke:
            return -(quantity ?? 1)
        case .gift:
            return -(quantity ?? 1)
        }
    }
    
    var effectivePrice: Decimal {
        guard let price = price, let quantity = quantity, quantity > 0 else {
            return 0
        }
        return price
    }
    
    init(quantity: Int? = nil,
         price: Decimal? = nil,
         vendor: String? = nil,
         url: String? = nil,
         notes: String? = nil,
         type: PurchaseType = .purchase) {
        self.quantity = quantity
        self.price = price
        self.vendor = vendor
        self.url = url
        self.notes = notes
        self.typeRawValue = type.rawValue
        self.date = Date()
    }
} 