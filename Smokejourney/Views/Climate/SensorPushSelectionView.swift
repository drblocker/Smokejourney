import SwiftUI
import SwiftData

struct SensorPushSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showAddSensor = false
    @State private var isLoading = false
    
    // Callback for selection mode
    var onSelect: ((String?) -> Void)?
    // Optional binding for humidor selection mode
    var selectedSensorID: Binding<String?>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if sensorPushManager.sensors.isEmpty {
                    ContentUnavailableView {
                        Label("No Sensors", systemImage: "sensor.fill")
                    } description: {
                        Text("Add a SensorPush sensor to monitor your humidors")
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(sensorPushManager.sensors) { sensor in
                            SensorRow(
                                sensor: sensor,
                                isSelected: selectedSensorID?.wrappedValue == sensor.id,
                                onSelect: {
                                    Task {
                                        await selectSensor(sensor.id)
                                    }
                                }
                            )
                            .environmentObject(viewModel)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            if sensor.id != sensorPushManager.sensors.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle("Select Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if let onSelect = onSelect {
                        onSelect(nil)
                    }
                    dismiss()
                }
            }
            
            if onSelect == nil && selectedSensorID == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSensor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSensor) {
            NavigationStack {
                ConnectSensorView()
            }
        }
        .task {
            isLoading = true
            defer { isLoading = false }
            
            await viewModel.fetchSensors()
            await fetchSensorData()
        }
    }
    
    private func selectSensor(_ sensorId: String) async {
        if let onSelect = onSelect {
            // Fetch latest data before selecting
            await viewModel.fetchLatestSample(for: sensorId)
            onSelect(sensorId)
        } else if let binding = selectedSensorID {
            await viewModel.fetchLatestSample(for: sensorId)
            binding.wrappedValue = sensorId
        }
        dismiss()
    }
    
    private func fetchSensorData() async {
        for sensor in sensorPushManager.sensors {
            await viewModel.fetchLatestSample(for: sensor.id)
        }
    }
}

private struct SensorRow: View {
    @EnvironmentObject private var viewModel: HumidorEnvironmentViewModel
    let sensor: SensorPushDevice
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(sensor.displayName)
                    if let sample = viewModel.getSensorSample(for: sensor.id) {
                        Text("\(String(format: "%.1f°F", sample.temperature)) | \(String(format: "%.1f%%", sample.humidity))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SensorPushSelectionView()
            .environmentObject(SensorPushService())
    }
} 