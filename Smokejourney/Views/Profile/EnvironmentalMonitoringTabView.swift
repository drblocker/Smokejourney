import SwiftUI
import SwiftData

struct EnvironmentalMonitoringTabView: View {
    @Query private var humidors: [Humidor]
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @EnvironmentObject private var homeKitManager: HomeKitService
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @State private var showingAddSensor = false
    @State private var selectedHumidor: Humidor?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    HStack {
                        Button(action: { showingAddSensor = true }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                Text("Add Sensor")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        
                        NavigationLink {
                            SensorManagementView()
                        } label: {
                            VStack {
                                Image(systemName: "gear")
                                    .font(.title)
                                Text("Manage")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active Sensors
                    VStack(alignment: .leading) {
                        Text("Active Sensors")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(humidors) { humidor in
                                    if let sensorId = humidor.sensorId {
                                        SensorPushCard(humidor: humidor, sensorId: sensorId)
                                    }
                                    if humidor.homeKitEnabled {
                                        HomeKitSensorCard(humidor: humidor)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Readings
                    VStack(alignment: .leading) {
                        Text("Recent Readings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(humidors) { humidor in
                            HumidorReadingsCard(humidor: humidor)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Environment")
            .sheet(isPresented: $showingAddSensor) {
                NavigationStack {
                    HumidorSensorSelectionSheet(selectedHumidor: $selectedHumidor)
                }
            }
        }
    }
}

// Supporting Views
struct SensorPushCard: View {
    let humidor: Humidor
    let sensorId: String
    @EnvironmentObject private var sensorPushManager: SensorPushService
    
    var body: some View {
        VStack(alignment: .leading) {
            if let sensor = sensorPushManager.sensors.first(where: { $0.id == sensorId }) {
                Text(sensor.displayName)
                    .font(.headline)
                Text("SensorPush")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct HomeKitSensorCard: View {
    let humidor: Humidor
    @EnvironmentObject private var homeKitManager: HomeKitService
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(humidor.effectiveName)
                .font(.headline)
            Text("HomeKit")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct HumidorReadingsCard: View {
    let humidor: Humidor
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(humidor.effectiveName)
                .font(.headline)
            if let sensorId = humidor.sensorId,
               let sample = viewModel.getSensorSample(for: sensorId) {
                HStack(spacing: 20) {
                    Text(String(format: "%.1f°F", (sample.temperature * 9/5) + 32))
                    Text(String(format: "%.1f%%", sample.humidity))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .task {
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
            }
        }
    }
}

struct HumidorSensorSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedHumidor: Humidor?
    @State private var showHumidorSelection = false
    @Query private var humidors: [Humidor]
    
    var body: some View {
        List {
            Section {
                Button {
                    showHumidorSelection = true
                } label: {
                    HStack {
                        Text(selectedHumidor?.effectiveName ?? "Select Humidor")
                        Spacer()
                        if selectedHumidor != nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            
            if let humidor = selectedHumidor {
                Section("Select Sensor Type") {
                    NavigationLink {
                        SensorPushSelectionView(selectedSensorID: .init(
                            get: { humidor.sensorId },
                            set: { newValue in
                                humidor.sensorId = newValue
                                try? modelContext.save()
                                dismiss()
                            }
                        ))
                    } label: {
                        HStack {
                            Image(systemName: "sensor.fill")
                            VStack(alignment: .leading) {
                                Text("SensorPush")
                                    .font(.headline)
                                Text("Connect to SensorPush devices")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        HumidorSensorSelectionView(
                            humidor: humidor,
                            selectedTempSensorID: .constant(humidor.homeKitTemperatureSensorID),
                            selectedHumiditySensorID: .constant(humidor.homeKitHumiditySensorID)
                        )
                    } label: {
                        HStack {
                            Image(systemName: "homekit")
                            VStack(alignment: .leading) {
                                Text("HomeKit")
                                    .font(.headline)
                                Text("Use HomeKit compatible sensors")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Add Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showHumidorSelection) {
            NavigationStack {
                List(humidors) { humidor in
                    Button {
                        selectedHumidor = humidor
                        showHumidorSelection = false
                    } label: {
                        Text(humidor.effectiveName)
                    }
                }
                .navigationTitle("Select Humidor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showHumidorSelection = false
                        }
                    }
                }
            }
        }
    }
}
