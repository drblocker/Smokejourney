import SwiftUI

struct SensorPushSelectionView: View {
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSensorID: String?
    
    var body: some View {
        List {
            if sensorPushManager.sensors.isEmpty {
                Text("No SensorPush sensors found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sensorPushManager.sensors) { sensor in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(sensor.displayName)
                            if let location = sensor.location {
                                Text(location)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if sensor.id == selectedSensorID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSensorID = sensor.id
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Select SensorPush Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            do {
                try await sensorPushManager.getSensors()
            } catch {
                print("Failed to fetch sensors: \(error.localizedDescription)")
            }
        }
    }
}