import SwiftUI

struct SensorSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: HumidorEnvironmentViewModel
    @Binding var selectedSensorId: String?
    
    init(selectedSensorId: Binding<String?>) {
        self._selectedSensorId = selectedSensorId
        self._viewModel = StateObject(wrappedValue: HumidorEnvironmentViewModel())
    }
    
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
                            selectedSensorId = sensor.id
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(sensor.displayName)
                                        .font(.headline)
                                    Text("ID: \(sensor.deviceId)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if sensor.id == selectedSensorId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Sensor")
        .task {
            await viewModel.fetchSensors()
        }
    }
} 