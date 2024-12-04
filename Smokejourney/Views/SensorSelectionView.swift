import SwiftUI
import SwiftData

struct SensorSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Bindable var humidor: Humidor
    
    var body: some View {
        List {
            Section {
                if viewModel.sensors.isEmpty {
                    ContentUnavailableView {
                        Label("No Sensors Available", systemImage: "sensor.fill")
                    } description: {
                        Text("Add sensors in Settings > SensorPush")
                    }
                } else {
                    ForEach(viewModel.sensors) { sensor in
                        Button(action: {
                            humidor.sensorId = sensor.id
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(sensor.name)
                                        .font(.headline)
                                    Text("ID: \(sensor.deviceId)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if sensor.id == humidor.sensorId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Available Sensors")
            } footer: {
                Text("Select a sensor to monitor this humidor's environment")
            }
        }
        .navigationTitle("Select Sensor")
        .task {
            await viewModel.fetchSensors()
        }
    }
} 