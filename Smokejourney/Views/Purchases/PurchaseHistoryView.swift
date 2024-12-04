import SwiftUI
import SwiftData

struct PurchaseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let cigar: Cigar
    @State private var purchaseToEdit: CigarPurchase?
    
    var body: some View {
        List {
            ForEach(cigar.purchases?.sorted { $0.date ?? Date() > $1.date ?? Date() } ?? [], id: \.self) { purchase in
                PurchaseRow(purchase: purchase)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deletePurchase(purchase)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        if purchase.quantity ?? 0 > 0 {  // Only allow editing purchases, not smokes
                            Button {
                                purchaseToEdit = purchase
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .navigationTitle("Purchase History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: AddPurchaseView(cigar: cigar)) {
                    Label("Add Purchase", systemImage: "plus")
                }
            }
        }
        .sheet(item: $purchaseToEdit) { purchase in
            NavigationStack {
                EditPurchaseView(purchase: purchase)
            }
        }
    }
    
    private func deletePurchase(_ purchase: CigarPurchase) {
        if let index = cigar.purchases?.firstIndex(where: { $0.id == purchase.id }) {
            cigar.purchases?.remove(at: index)
        }
    }
} 