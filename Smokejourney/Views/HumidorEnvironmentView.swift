import SwiftUI

struct HumidorEnvironmentView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Bindable var humidor: Humidor
    @State private var showSensorSelection = false
    @State private var selectedSensorType: SensorType?
    @State private var selectedTempSensorID: String?
    @State private var selectedHumiditySensorID: String?
    
    enum SensorType {
        case sensorPush
        case homeKit
    }
    
    var body: some View {
        List {
            // SensorPush Section
            Section("SensorPush") {
                if let sensorId = humidor.sensorId,
                   let sensor = viewModel.sensors.first(where: { $0.id == sensorId }) {
                    VStack(alignment: .leading) {
                        Text(sensor.displayName)
                            .font(.headline)
                        if let sample = viewModel.getSensorSample(for: sensorId) {
                            HStack(spacing: 20) {
                                SensorReadingView(
                                    title: "Temperature",
                                    value: String(format: "%.1f°F", (sample.temperature * 9/5) + 32),
                                    status: viewModel.getTemperatureStatus(sample.temperature)
                                )
                                SensorReadingView(
                                    title: "Humidity",
                                    value: String(format: "%.1f%%", sample.humidity),
                                    status: viewModel.getHumidityStatus(sample.humidity)
                                )
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(action: { 
                        selectedSensorType = .sensorPush
                        showSensorSelection = true 
                    }) {
                        Label("Add SensorPush Device", systemImage: "plus.circle")
                    }
                }
            }
            
            // HomeKit Section
            Section("HomeKit") {
                if humidor.homeKitEnabled {
                    if let tempId = humidor.homeKitTemperatureSensorID,
                       let humId = humidor.homeKitHumiditySensorID {
                        VStack(alignment: .leading) {
                            Text("Temperature & Humidity")
                                .font(.headline)
                            if let temp = viewModel.temperature,
                               let hum = viewModel.humidity {
                                HStack(spacing: 20) {
                                    SensorReadingView(
                                        title: "Temperature",
                                        value: String(format: "%.1f°F", (temp * 9/5) + 32),
                                        status: viewModel.temperatureStatus
                                    )
                                    SensorReadingView(
                                        title: "Humidity",
                                        value: String(format: "%.1f%%", hum),
                                        status: viewModel.humidityStatus
                                    )
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: { 
                            selectedSensorType = .homeKit
                            showSensorSelection = true 
                        }) {
                            Label("Add HomeKit Sensors", systemImage: "plus.circle")
                        }
                    }
                } else {
                    Button(action: { 
                        selectedSensorType = .homeKit
                        showSensorSelection = true 
                    }) {
                        Label("Enable HomeKit", systemImage: "homekit")
                    }
                }
            }
        }
        .navigationTitle("Environment")
        .sheet(isPresented: $showSensorSelection) {
            NavigationStack {
                if selectedSensorType == .sensorPush {
                    SensorPushSelectionView(selectedSensorID: $humidor.sensorId)
                } else {
                    HumidorSensorSelectionView(
                        humidor: humidor,
                        selectedTempSensorID: $selectedTempSensorID,
                        selectedHumiditySensorID: $selectedHumiditySensorID
                    )
                }
            }
        }
        .task {
            await viewModel.fetchSensors()
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
            }
        }
    }
}

struct SensorReadingView: View {
    let title: String
    let value: String
    let status: EnvironmentStatus
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(status.color)
        }
    }
}

#Preview {
    HumidorEnvironmentView(humidor: Humidor())
} 
