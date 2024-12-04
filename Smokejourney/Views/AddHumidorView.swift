import SwiftUI
import SwiftData

struct AddHumidorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var capacityString = ""
    @State private var location = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var isValidCapacity: Bool {
        guard let capacity = Int(capacityString) else { return false }
        return capacity >= 1 && capacity <= 1000
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Capacity", text: $capacityString)
                        .keyboardType(.numberPad)
                    TextField("Location (Optional)", text: $location)
                }
                
                Section {
                    Text("Enter a number between 1 and 1000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Humidor")
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
        
        guard capacityValue >= 1 && capacityValue <= 1000 else {
            alertMessage = "Capacity must be between 1 and 1000"
            showAlert = true
            return false
        }
        
        let humidor = Humidor(
            name: name,
            capacity: capacityValue,
            location: location.isEmpty ? nil : location
        )
        
        modelContext.insert(humidor)
        return true
    }
} 