import SwiftUI
import SwiftData

struct HumidorCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var capacity = 25
    @State private var description = ""
    @State private var location = ""
    
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
        .navigationTitle("New Humidor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    createHumidor()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func createHumidor() {
        let humidor = Humidor(
            name: name,
            capacity: capacity,
            description: description.isEmpty ? nil : description,
            location: location.isEmpty ? nil : location
        )
        modelContext.insert(humidor)
        dismiss()
    }
} 