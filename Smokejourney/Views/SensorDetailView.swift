import SwiftUI
import Charts

struct SensorDetailView: View {
    let sensor: SensorPushDevice
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var temperatureOffset: Double
    @State private var humidityOffset: Double
    
    private let defaults: UserDefaults
    
    init(sensor: SensorPushDevice, defaults: UserDefaults = .standard) {
        self.sensor = sensor
        self.defaults = defaults
        
        let tempKey = "tempOffset_\(sensor.id)"
        let humidityKey = "humidityOffset_\(sensor.id)"
        
        defaults.register(defaults: [
            tempKey: 0.0,
            humidityKey: 0.0
        ])
        
        self._temperatureOffset = State(initialValue: defaults.double(forKey: tempKey))
        self._humidityOffset = State(initialValue: defaults.double(forKey: humidityKey))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                sensorInformationCard
                calibrationCard
                healthCard
                if !viewModel.historicalData.isEmpty {
                    historicalDataCard
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Sensor Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchLatestSample(for: sensor.id)
        }
        .onChange(of: temperatureOffset) { newValue in
            defaults.set(newValue, forKey: "tempOffset_\(sensor.id)")
        }
        .onChange(of: humidityOffset) { newValue in
            defaults.set(newValue, forKey: "humidityOffset_\(sensor.id)")
        }
    }
    
    private var sensorInformationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensor Information")
                .font(.headline)
            
            infoRow(title: "Name", value: sensor.displayName)
            infoRow(title: "Device ID", value: sensor.deviceId)
            infoRow(title: "Status", value: sensor.active ? "Active" : "Inactive", 
                   color: sensor.active ? .green : .red)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private var calibrationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calibration")
                .font(.headline)
            
            calibrationSlider(title: "Temperature Offset",
                            value: $temperatureOffset,
                            range: -10...10,
                            step: 0.5,
                            format: "%.1f°F")
            
            calibrationSlider(title: "Humidity Offset",
                            value: $humidityOffset,
                            range: -20...20,
                            step: 1.0,
                            format: "%.0f%%")
            
            Button(action: resetOffsets) {
                Text("Reset Calibration")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private func infoRow(title: String, value: String, color: Color = .secondary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(color)
        }
    }
    
    private func calibrationSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Slider(value: value, in: range, step: step)
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .frame(width: 60)
            }
        }
    }
    
    private func resetOffsets() {
        temperatureOffset = 0.0
        humidityOffset = 0.0
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
    
    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health")
                .font(.headline)
            
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
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private var historicalDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 24 Hours")
                .font(.headline)
            
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
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

private struct UserDefaultsKey: EnvironmentKey {
    static let defaultValue = UserDefaults.standard
}

extension EnvironmentValues {
    var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self] }
        set { self[UserDefaultsKey.self] = newValue }
    }
}