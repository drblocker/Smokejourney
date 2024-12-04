import SwiftUI
import SwiftData
import Foundation

struct PurchaseRow: View {
    let purchase: CigarPurchase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(purchase.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Label(
                    getTransactionLabel(),
                    systemImage: getTransactionIcon()
                )
                .foregroundColor(getTransactionColor())
                
                Spacer()
                
                if purchase.purchaseType == .purchase,
                   let price = purchase.price,
                   let formattedPrice = currencyFormatter.string(from: price as NSDecimalNumber) {
                    Text(formattedPrice)
                }
            }
            
            if let vendor = purchase.vendor {
                Text(purchase.purchaseType == .gift ? "To: \(vendor)" : vendor)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = purchase.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    private func getTransactionLabel() -> String {
        switch purchase.purchaseType {
        case .purchase:
            return "Added: \(purchase.quantity ?? 0)"
        case .smoke:
            return "Smoked"
        case .gift:
            return "Gifted: \(abs(purchase.quantity ?? 0))"
        }
    }
    
    private func getTransactionIcon() -> String {
        switch purchase.purchaseType {
        case .purchase: return "plus.circle.fill"
        case .smoke: return "flame.fill"
        case .gift: return "gift.fill"
        }
    }
    
    private func getTransactionColor() -> Color {
        switch purchase.purchaseType {
        case .purchase: return .green
        case .smoke: return .orange
        case .gift: return .purple
        }
    }
} 