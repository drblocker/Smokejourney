import SwiftUI
import SwiftData

struct SensorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let sensor: Sensor
    
    @State private var customName: String
    @State private var location: String
    @State private var showAlert = false
    
    init(sensor: Sensor) {
        self.sensor = sensor
        _customName = State(initialValue: sensor.customName ?? sensor.name ?? "")
        _location = State(initialValue: sensor.location ?? "")
    }
    
    var body: some View {
        Form {
            Section("Sensor Information") {
                // Original sensor info (read-only)
                if let id = sensor.id {
                    LabeledContent("Sensor ID", value: id)
                }
                if let type = sensor.type {
                    LabeledContent("Type", value: type.description)
                }
                
                // Editable fields
                TextField("Custom Name", text: $customName)
                TextField("Location", text: $location, 
                         prompt: Text("e.g., Top Shelf, Bottom Right"))
            }
            
            Section("Current Readings") {
                if let reading = sensor.lastReading,
                   let timestamp = reading.timestamp {
                    if let temperature = reading.temperature {
                        LabeledContent("Temperature") {
                            Text(String(format: "%.1f°F", temperature))
                        }
                    }
                    if let humidity = reading.humidity {
                        LabeledContent("Humidity") {
                            Text(String(format: "%.1f%%", humidity))
                        }
                    }
                    Text("Last Updated: \(timestamp, style: .relative)")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button("Remove Sensor", role: .destructive) {
                    showAlert = true
                }
            }
        }
        .navigationTitle(sensor.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSensorSettings()
                }
            }
        }
        .alert("Remove Sensor", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeSensor()
            }
        } message: {
            Text("Are you sure you want to remove this sensor? You'll need to pair it again to use it.")
        }
    }
    
    private func saveSensorSettings() {
        sensor.customName = customName.isEmpty ? nil : customName
        sensor.location = location.isEmpty ? nil : location
        try? modelContext.save()
        dismiss()
    }
    
    private func removeSensor() {
        sensor.humidor = nil
        modelContext.delete(sensor)
        dismiss()
    }
} 