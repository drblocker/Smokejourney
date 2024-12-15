import SwiftUI
import SwiftData

struct HumidorEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var humidor: Humidor
    
    @State private var name: String
    @State private var capacity: Int
    @State private var description: String
    @State private var location: String
    
    init(humidor: Humidor) {
        self.humidor = humidor
        _name = State(initialValue: humidor.effectiveName)
        _capacity = State(initialValue: humidor.effectiveCapacity)
        _description = State(initialValue: humidor.humidorDescription ?? "")
        _location = State(initialValue: humidor.location ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Capacity", value: $capacity, format: .number)
                    .keyboardType(.numberPad)
            }
            
            Section {
                TextField("Description", text: $description)
                TextField("Location", text: $location)
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
                    saveChanges()
                }
            }
        }
    }
    
    private func saveChanges() {
        humidor.name = name
        humidor.capacity = capacity
        humidor.humidorDescription = description.isEmpty ? nil : description
        humidor.location = location.isEmpty ? nil : location
        
        try? modelContext.save()
        dismiss()
    }
} 