import SwiftUI
import Charts

struct SensorDetailView: View {
    let sensor: SensorPushDevice
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage private var temperatureOffset: Double
    @AppStorage private var humidityOffset: Double
    
    init(sensor: SensorPushDevice) {
        self.sensor = sensor
        _temperatureOffset = AppStorage(wrappedValue: 0.0, "tempOffset_\(sensor.id)")
        _humidityOffset = AppStorage(wrappedValue: 0.0, "humidityOffset_\(sensor.id)")
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(sensor.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Device ID")
                    Spacer()
                    Text(sensor.deviceId)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(sensor.type)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(sensor.active ? "Active" : "Inactive")
                        .foregroundColor(sensor.active ? .green : .red)
                }
            } header: {
                Text("Sensor Information")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("Temperature Offset")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Slider(value: $temperatureOffset, in: -10...10, step: 0.5)
                        Text(String(format: "%.1f°F", temperatureOffset))
                            .monospacedDigit()
                            .frame(width: 60)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Humidity Offset")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Slider(value: $humidityOffset, in: -20...20, step: 1)
                        Text(String(format: "%.0f%%", humidityOffset))
                            .monospacedDigit()
                            .frame(width: 60)
                    }
                }
                
                Button(action: resetOffsets) {
                    Text("Reset Calibration")
                }
                .foregroundColor(.red)
            } header: {
                Text("Calibration")
            } footer: {
                Text("Offsets are applied to sensor readings to account for any calibration differences.")
            }
            
            Section {
                HStack {
                    // Battery status
                    HStack {
                        Image(systemName: batteryIcon(sensor.batteryVoltage))
                            .foregroundColor(batteryColor(sensor.batteryVoltage))
                        Text(formatBattery(sensor.batteryVoltage))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Signal strength
                    HStack {
                        Image(systemName: signalIcon(sensor.rssi))
                            .foregroundColor(signalColor(sensor.rssi))
                        Text(formatSignal(sensor.rssi))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Health")
            }
            
            if !viewModel.historicalData.isEmpty {
                Section {
                    VStack {
                        Chart(viewModel.historicalData, id: \.timestamp) { data in
                            LineMark(
                                x: .value("Time", data.timestamp),
                                y: .value("Temperature", data.temperature + temperatureOffset)
                            )
                            .foregroundStyle(.red)
                            
                            LineMark(
                                x: .value("Time", data.timestamp),
                                y: .value("Humidity", data.humidity + humidityOffset)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 180)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                Text("Temperature")
                                    .font(.caption)
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text("Humidity")
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Last 24 Hours")
                }
            }
        }
        .navigationTitle("Sensor Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchLatestSample(for: sensor.id)
        }
    }
    
    private func resetOffsets() {
        temperatureOffset = 0
        humidityOffset = 0
    }
    
    // Helper functions from SensorRowView
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
        case ...(-70): return "wifi.slash"
        case ...(-60): return "wifi"
        default: return "wifi.square.fill"
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