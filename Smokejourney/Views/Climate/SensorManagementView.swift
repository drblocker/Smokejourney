import SwiftUI
import SwiftData

struct SensorManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var sensors: [ClimateSensor]
    
    var body: some View {
        List {
            ForEach(sensors) { sensor in
                SensorRow(sensor: sensor)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(sensors[index])
                }
            }
        }
        .navigationTitle("Manage Sensors")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct SensorRow: View {
    let sensor: ClimateSensor
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(sensor.name ?? "Unnamed Sensor")
                .font(.headline)
            
            HStack {
                Image(systemName: sensor.type == .homeKit ? "homekit" : "sensor.fill")
                Text(sensor.type == .homeKit ? "HomeKit" : "SensorPush")
                    .foregroundStyle(.secondary)
                
                if let temp = sensor.currentTemperature,
                   let humidity = sensor.currentHumidity {
                    Spacer()
                    Text(String(format: "%.1f°F", temp))
                    Text(String(format: "%.1f%%", humidity))
                }
            }
            .font(.caption)
        }
    }
}

#Preview {
    NavigationStack {
        SensorManagementView()
    }
    .modelContainer(for: ClimateSensor.self, inMemory: true)
} 