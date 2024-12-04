import SwiftUI
import SwiftData

struct AddPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    let cigar: Cigar
    
    @State private var quantity = 1
    @State private var priceString = ""
    @State private var vendor = ""
    @State private var url = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Purchase Date", selection: $date, displayedComponents: [.date])
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Price (total)", text: $priceString)
                        .keyboardType(.decimalPad)
                    
                    TextField("Vendor", text: $vendor)
                    
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                if !priceString.isEmpty {
                    Section {
                        if let price = Decimal(string: priceString),
                           let pricePerCigar = currencyFormatter.string(from: (price / Decimal(quantity)) as NSDecimalNumber) {
                            Text("Price per cigar: \(pricePerCigar)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateAndSave() {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        quantity > 0 && (priceString.isEmpty || Decimal(string: priceString) != nil)
    }
    
    private func validateAndSave() -> Bool {
        guard quantity > 0 else { return false }
        
        if !priceString.isEmpty {
            guard let _ = Decimal(string: priceString) else { return false }
        }
        
        if !url.isEmpty {
            guard URL(string: url) != nil else { return false }
        }
        
        savePurchase()
        return true
    }
    
    private func savePurchase() {
        let purchase = CigarPurchase(
            quantity: quantity,
            price: Decimal(string: priceString),
            vendor: vendor.isEmpty ? nil : vendor,
            url: url.isEmpty ? nil : url
        )
        purchase.date = date
        purchase.cigar = cigar
        
        if cigar.purchases == nil {
            cigar.purchases = []
        }
        cigar.purchases?.append(purchase)
    }
} 