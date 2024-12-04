import SwiftData
import Foundation

@Model
final class CigarPurchase {
    var quantity: Int?
    var price: Decimal?
    var date: Date?
    var vendor: String?
    var url: String?
    var cigar: Cigar?
    
    init(quantity: Int, price: Decimal?, vendor: String? = nil, url: String? = nil) {
        self.quantity = quantity
        self.price = price
        self.date = Date()
        self.vendor = vendor
        self.url = url
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
} 