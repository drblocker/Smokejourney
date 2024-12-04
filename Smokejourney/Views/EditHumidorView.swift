import SwiftUI
import SwiftData

struct EditHumidorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var humidor: Humidor
    
    @State private var name: String
    @State private var capacityString: String
    @State private var location: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Computed property to handle capacity validation
    private var capacity: Int {
        return Int(capacityString) ?? humidor.effectiveCapacity
    }
    
    private var isValidCapacity: Bool {
        guard let value = Int(capacityString) else { return false }
        return value >= humidor.effectiveCigars.count && value <= 1000
    }
    
    init(humidor: Humidor) {
        self.humidor = humidor
        _name = State(initialValue: humidor.effectiveName)
        _capacityString = State(initialValue: String(humidor.effectiveCapacity))
        _location = State(initialValue: humidor.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Humidor Details") {
                    TextField("Name", text: $name)
                    
                    TextField("Capacity", text: $capacityString)
                        .keyboardType(.numberPad)
                    
                    TextField("Location (Optional)", text: $location)
                }
                
                Section("Capacity Guidelines") {
                    Text("Enter a number between \(humidor.effectiveCigars.count) and 1000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Current Status") {
                    Text("Current cigars: \(humidor.effectiveCigars.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Humidor")
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
                    .disabled(name.isEmpty || !isValidCapacity)
                }
            }
            .alert("Invalid Input", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateAndSave() -> Bool {
        guard let capacityValue = Int(capacityString) else {
            alertMessage = "Please enter a valid number for capacity"
            showAlert = true
            return false
        }
        
        guard capacityValue >= humidor.effectiveCigars.count else {
            alertMessage = "Capacity cannot be less than current number of cigars (\(humidor.effectiveCigars.count))"
            showAlert = true
            return false
        }
        
        guard capacityValue <= 1000 else {
            alertMessage = "Capacity must be between \(humidor.effectiveCigars.count) and 1000"
            showAlert = true
            return false
        }
        
        humidor.name = name
        humidor.capacity = capacityValue
        humidor.location = location.isEmpty ? nil : location
        return true
    }
} 