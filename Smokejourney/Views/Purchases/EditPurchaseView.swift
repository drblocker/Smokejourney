import SwiftUI
import SwiftData

struct EditPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var purchase: CigarPurchase
    
    @State private var quantity: Int
    @State private var priceString: String
    @State private var vendor: String
    @State private var url: String
    @State private var date: Date
    
    init(purchase: CigarPurchase) {
        self.purchase = purchase
        _quantity = State(initialValue: purchase.quantity ?? 0)
        _priceString = State(initialValue: purchase.price?.description ?? "")
        _vendor = State(initialValue: purchase.vendor ?? "")
        _url = State(initialValue: purchase.url ?? "")
        _date = State(initialValue: purchase.date ?? Date())
    }
    
    var body: some View {
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
        .navigationTitle("Edit Purchase")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if saveChanges() {
                        dismiss()
                    }
                }
                .disabled(!isValid)
            }
        }
    }
    
    private var isValid: Bool {
        quantity > 0 && (priceString.isEmpty || Decimal(string: priceString) != nil)
    }
    
    private func saveChanges() -> Bool {
        guard quantity > 0 else { return false }
        
        if !priceString.isEmpty {
            guard let _ = Decimal(string: priceString) else { return false }
        }
        
        if !url.isEmpty {
            guard URL(string: url) != nil else { return false }
        }
        
        purchase.quantity = quantity
        purchase.price = Decimal(string: priceString)
        purchase.vendor = vendor.isEmpty ? nil : vendor
        purchase.url = url.isEmpty ? nil : url
        purchase.date = date
        
        return true
    }
} 