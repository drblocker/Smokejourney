import SwiftUI
import SwiftData

struct GiftCigarView: View {
    @Environment(\.dismiss) private var dismiss
    let cigar: Cigar
    
    @State private var quantity = 1
    @State private var recipient = ""
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Recipient", text: $recipient)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Text("Current Inventory: \(cigar.totalQuantity)")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Gift Cigar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if saveGift() {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        quantity > 0 && quantity <= cigar.totalQuantity && !recipient.isEmpty
    }
    
    private func saveGift() -> Bool {
        let gift = CigarPurchase(
            quantity: quantity,
            price: nil,
            vendor: recipient,    // Use vendor field to store recipient
            url: nil,
            notes: notes.isEmpty ? nil : notes,  // Pass notes
            type: .gift
        )
        gift.date = date
        gift.cigar = cigar
        
        if cigar.purchases == nil {
            cigar.purchases = []
        }
        cigar.purchases?.append(gift)
        
        return true
    }
} 