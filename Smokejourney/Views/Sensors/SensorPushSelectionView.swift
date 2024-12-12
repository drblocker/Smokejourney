import SwiftUI
import SwiftData

struct SensorPushSelectionView: View {
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showAddSensor = false
    
    // Optional binding for selection mode
    var selectedSensorID: Binding<String?>?
    
    // Initialize for display mode (default)
    init() { }
    
    // Initialize for selection mode
    init(selectedSensorID: Binding<String?>) {
        self.selectedSensorID = selectedSensorID
    }
    
    var body: some View {
        List {
            if sensorPushManager.sensors.isEmpty {
                ContentUnavailableView {
                    Label("No Sensors", systemImage: "sensor.fill")
                } description: {
                    Text("Add a SensorPush sensor to monitor your humidors")
                }
            } else {
                ForEach(sensorPushManager.sensors) { sensor in
                    if selectedSensorID != nil {
                        // Selection mode
                        Button {
                            selectedSensorID?.wrappedValue = sensor.id
                            dismiss()
                        } label: {
                            SensorRow(sensor: sensor, isSelected: sensor.id == selectedSensorID?.wrappedValue)
                        }
                    } else {
                        // Display mode
                        NavigationLink {
                            SensorDetailView(sensor: sensor)
                        } label: {
                            SensorRow(sensor: sensor, isSelected: false)
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedSensorID != nil ? "Select Sensor" : "SensorPush")
        .toolbar {
            if selectedSensorID == nil {  // Only show add button in display mode
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
            do {
                try await sensorPushManager.getSensors()
                for sensor in sensorPushManager.sensors {
                    await viewModel.fetchLatestSample(for: sensor.id)
                }
            } catch {
                print("Failed to fetch sensors: \(error.localizedDescription)")
            }
        }
    }
}

// Helper view for sensor row
private struct SensorRow: View {
    let sensor: SensorPushDevice
    let isSelected: Bool
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(sensor.displayName)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                } else {
                    StatusIndicator(sensor: sensor)
                }
            }
            
            if let location = sensor.location {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let sample = viewModel.getSensorSample(for: sensor.id) {
                HStack(spacing: 20) {
                    Text(String(format: "%.1f°F", (sample.temperature * 9/5) + 32))
                        .font(.subheadline)
                    Text(String(format: "%.1f%%", sample.humidity))
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .task {
            await viewModel.fetchLatestSample(for: sensor.id)
        }
    }
}

// Helper view for adding sensors
struct ConnectSensorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @State private var selectedHumidor: Humidor?
    
    var body: some View {
        List {
            Section {
                if let selectedHumidor = selectedHumidor {
                    Text(selectedHumidor.effectiveName)
                } else {
                    NavigationLink("Select Humidor") {
                        HumidorSelectionView(selectedHumidor: $selectedHumidor)
                    }
                }
            }
            
            if let humidor = selectedHumidor {
                Section("Available Sensors") {
                    ForEach(sensorPushManager.sensors) { sensor in
                        Button {
                            humidor.sensorId = sensor.id
                            try? modelContext.save()
                            dismiss()
                        } label: {
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
                                if isInUse(sensor) {
                                    Text("In Use")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(isInUse(sensor))
                    }
                }
            }
        }
        .navigationTitle("Connect Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func isInUse(_ sensor: SensorPushDevice) -> Bool {
        let context = modelContext
        let descriptor = FetchDescriptor<Humidor>()
        if let humidors = try? context.fetch(descriptor) {
            return humidors.contains { $0.sensorId == sensor.id }
        }
        return false
    }
}

struct HumidorSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedHumidor: Humidor?
    
    var body: some View {
        let descriptor = FetchDescriptor<Humidor>()
        let humidors = (try? modelContext.fetch(descriptor)) ?? []
        
        List(humidors) { humidor in
            Button {
                selectedHumidor = humidor
                dismiss()
            } label: {
                Text(humidor.effectiveName)
            }
        }
        .navigationTitle("Select Humidor")
    }
}