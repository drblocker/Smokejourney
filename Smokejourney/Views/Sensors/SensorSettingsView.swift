import SwiftUI
import SwiftData

struct SensorSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let sensor: Sensor
    @State private var customName: String
    @State private var location: String
    
    init(sensor: Sensor) {
        self.sensor = sensor
        // Initialize state with current values
        _customName = State(initialValue: sensor.customName ?? "")
        _location = State(initialValue: sensor.location ?? "")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Custom Name", text: $customName)
                TextField("Location", text: $location)
            } header: {
                Text("Sensor Information")
            }
            
            Section {
                if let readings = sensor.readings,
                   let reading = readings.last,
                   let temperature = reading.temperature,
                   let humidity = reading.humidity,
                   let timestamp = reading.timestamp {
                    LabeledContent("Temperature") {
                        Text(String(format: "%.1f°F", temperature))
                    }
                    
                    LabeledContent("Humidity") {
                        Text(String(format: "%.1f%%", humidity))
                    }
                    
                    Text("Last Updated: \(timestamp, style: .relative)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Current Readings")
            }
            
            Section {
                Button(role: .destructive) {
                    deleteSensor()
                } label: {
                    Text("Delete Sensor")
                }
            }
        }
        .navigationTitle(sensor.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveSensor()
                }
            }
        }
    }
    
    private func saveSensor() {
        sensor.customName = customName.isEmpty ? nil : customName
        sensor.location = location.isEmpty ? nil : location
        dismiss()
    }
    
    private func deleteSensor() {
        modelContext.delete(sensor)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SensorSettingsView(sensor: Sensor(name: "Test Sensor", type: .homeKit))
    }
    .modelContainer(for: Sensor.self, inMemory: true)
} 