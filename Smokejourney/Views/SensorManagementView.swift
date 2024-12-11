import SwiftUI
import SwiftData

struct SensorManagementView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @AppStorage("sensorPushAuthenticated") private var isAuthenticated = false
    @State private var showSensorDetails = false
    @State private var selectedSensor: SensorPushDevice?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            if !isAuthenticated {
                Section {
                    ContentUnavailableView {
                        Label("Not Connected", systemImage: "sensor.fill")
                    } description: {
                        Text("Please sign in to SensorPush in Profile settings to manage your sensors")
                    }
                }
            } else {
                Section {
                    if viewModel.sensors.isEmpty {
                        ContentUnavailableView {
                            Label("No Sensors", systemImage: "sensor.fill")
                        } description: {
                            Text("No SensorPush sensors found")
                        }
                    } else {
                        ForEach(viewModel.sensors) { sensor in
                            SensorRowView(sensor: sensor)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSensor = sensor
                                    showSensorDetails = true
                                }
                        }
                    }
                } header: {
                    if !viewModel.sensors.isEmpty {
                        Text("Available Sensors")
                    }
                }
                
                Section {
                    NavigationLink(destination: HumidorAlertSettingsView()) {
                        Label("Alert Settings", systemImage: "bell.badge")
                    }
                }
            }
        }
        .navigationTitle("Sensors")
        .sheet(item: $selectedSensor) { sensor in
            NavigationStack {
                SensorDetailView(sensor: sensor)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            if isAuthenticated {
                await viewModel.fetchSensors()
            }
        }
        .refreshable {
            if isAuthenticated {
                await viewModel.fetchSensors()
            }
        }
    }
}

struct SensorRowView: View {
    let sensor: SensorPushDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sensor.displayName)
                    .font(.headline)
                Spacer()
                StatusIndicator(sensor: sensor)
            }
            
            HStack {
                Label {
                    Text(formatBattery(sensor.batteryVoltage))
                } icon: {
                    Image(systemName: batteryIcon(sensor.batteryVoltage))
                        .foregroundColor(batteryColor(sensor.batteryVoltage))
                }
                
                Spacer()
                
                Label {
                    Text(formatSignal(sensor.rssi))
                } icon: {
                    Image(systemName: signalIcon(sensor.rssi))
                        .foregroundColor(signalColor(sensor.rssi))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if let location = sensor.location {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    
    private func batteryColor(_ voltage: Double) -> Color {
        let percentage = (voltage - 2.2) / (3.0 - 2.2)
        switch percentage {
        case ..<0.2: return .red
        case ..<0.4: return .orange
        default: return .green
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
    
    private func signalColor(_ rssi: Int) -> Color {
        switch rssi {
        case ...(-90): return .red
        case ...(-70): return .orange
        default: return .green
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