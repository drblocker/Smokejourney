import SwiftUI
import Charts

struct SensorDetailView: View {
    let sensor: Sensor
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Sensor Information") {
                LabeledContent("Name", value: sensor.name)
                LabeledContent("Device ID", value: sensor.deviceId)
                LabeledContent("Type", value: sensor.type)
                LabeledContent("Status", value: sensor.active ? "Active" : "Inactive")
            }
            
            Section("Health") {
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
            }
            
            if !viewModel.historicalData.isEmpty {
                Section("Last 24 Hours") {
                    Chart {
                        ForEach(viewModel.historicalData, id: \.timestamp) { data in
                            LineMark(
                                x: .value("Time", data.timestamp),
                                y: .value("Temperature", data.temperature)
                            )
                            .foregroundStyle(.red)
                            
                            LineMark(
                                x: .value("Time", data.timestamp),
                                y: .value("Humidity", data.humidity)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
        .navigationTitle(sensor.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchLatestSample(for: sensor.id)
        }
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