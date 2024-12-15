import SwiftUI
import SwiftData

struct AddHumidorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var capacity = 25
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...1000)
                } header: {
                    Text("Details")
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                } header: {
                    Text("Notes")
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
                    Button("Add") {
                        saveHumidor()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveHumidor() {
        let humidor = Humidor(name: name, capacity: capacity)
        humidor.notes = notes.isEmpty ? nil : notes
        modelContext.insert(humidor)
        dismiss()
    }
} 