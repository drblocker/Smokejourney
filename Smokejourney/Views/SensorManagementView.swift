import SwiftUI
import SwiftData
import os.log

struct SensorManagementView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showAddSensor = false
    @State private var showSensorDetails = false
    @State private var selectedSensor: SensorPushDevice?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.sensors) { sensor in
                    SensorRowView(sensor: sensor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSensor = sensor
                            showSensorDetails = true
                        }
                }
            } header: {
                if !viewModel.sensors.isEmpty {
                    Text("Connected Sensors")
                }
            }
            
            if viewModel.sensors.isEmpty {
                ContentUnavailableView {
                    Label("No Sensors", systemImage: "sensor.fill")
                } description: {
                    Text("Add a SensorPush sensor to monitor your humidor")
                } actions: {
                    Button(action: { showAddSensor = true }) {
                        Text("Add Sensor")
                    }
                }
            }
        }
        .navigationTitle("Sensors")
        .toolbar {
            if !viewModel.sensors.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSensor = true }) {
                        Label("Add Sensor", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSensor) {
            NavigationStack {
                SensorPushAuthView()
            }
        }
        .sheet(item: $selectedSensor) { sensor in
            NavigationStack {
                SensorDetailView(sensor: sensor)
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await viewModel.fetchSensors()
        }
    }
}

struct SensorRowView: View {
    let sensor: SensorPushDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sensor.name)
                    .font(.headline)
                Spacer()
                StatusIndicator(sensor: sensor)
            }
            
            HStack {
                Label {
                    Text(formatBattery(sensor.batteryVoltage))
                } icon: {
                    Image(systemName: batteryIcon(sensor.batteryVoltage))
                }
                
                Spacer()
                
                Label {
                    Text(formatSignal(sensor.rssi))
                } icon: {
                    Image(systemName: signalIcon(sensor.rssi))
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func formatBattery(_ voltage: Double) -> String {
        let percentage = min(max((voltage - 2.2) / (3.0 - 2.2) * 100, 0), 100)
        return String(format: "%.0f%%", percentage)
    }
    
    private func batteryIcon(_ voltage: Double) -> String {
        let percentage = (voltage - 2.2) / (3.0 - 2.2)
        switch percentage {
        case ..<0.2: return "battery.0"
        case ..<0.4: return "battery.25"
        case ..<0.6: return "battery.50"
        case ..<0.8: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private func formatSignal(_ rssi: Int) -> String {
        return "\(rssi) dBm"
    }
    
    private func signalIcon(_ rssi: Int) -> String {
        switch rssi {
        case ...(-90): return "wifi.exclamationmark"
        case ...(-70): return "wifi.1"
        case ...(-60): return "wifi.2"
        default: return "wifi"
        }
    }
}

struct StatusIndicator: View {
    let sensor: SensorPushDevice
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(sensor.active ? .green : .red)
                .frame(width: 8, height: 8)
            Text(sensor.active ? "Active" : "Inactive")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 