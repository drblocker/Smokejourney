import SwiftUI
import HomeKit
import os.log

struct EnvironmentalMonitoringView: View {
    @Bindable var humidor: Humidor
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showSensorSelection = false
    @State private var showAlertSettings = false
    @State private var showEnvironmentHistory = false
    @State private var showEnvironmentReport = false
    @StateObject private var homeKit = HomeKitService.shared
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "EnvironmentalMonitoring")
    
    var body: some View {
        Group {
            if let sensorId = humidor.sensorId {
                // Sensor is connected
                VStack(spacing: 12) {
                    // Sensor Status and Controls
                    HStack {
                        if let sensor = viewModel.sensors.first(where: { $0.id == sensorId }) {
                            NavigationLink(destination: SensorDetailView(sensor: sensor)) {
                                Label("View Sensor", systemImage: "sensor.fill")
                            }
                        } else {
                            Text("Loading sensor...")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button(action: { showEnvironmentHistory = true }) {
                                Label("View History", systemImage: "clock")
                            }
                            
                            Button(action: { showEnvironmentReport = true }) {
                                Label("View Report", systemImage: "chart.bar.doc.horizontal")
                            }
                            
                            Button(action: { showAlertSettings = true }) {
                                Label("Alert Settings", systemImage: "bell.badge")
                            }
                            
                            Button(role: .destructive, action: { humidor.sensorId = nil }) {
                                Label("Remove Sensor", systemImage: "minus.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        
                        if homeKit.isAuthorized {
                            Menu {
                                ForEach(homeKit.temperatureSensors, id: \.uniqueIdentifier) { sensor in
                                    Label(sensor.name, systemImage: "thermometer")
                                }
                                ForEach(homeKit.humiditySensors, id: \.uniqueIdentifier) { sensor in
                                    Label(sensor.name, systemImage: "humidity")
                                }
                                NavigationLink(destination: HomeKitSettingsView()) {
                                    Label("HomeKit Settings", systemImage: "gear")
                                }
                            } label: {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } else {
                // No sensor connected
                Button(action: { showSensorSelection = true }) {
                    Label("Add Sensor", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showSensorSelection) {
            NavigationStack {
                SensorSelectionView(humidor: humidor)
            }
        }
        .sheet(isPresented: $showAlertSettings) {
            NavigationStack {
                HumidorAlertSettingsView()
            }
        }
        .sheet(isPresented: $showEnvironmentHistory) {
            NavigationStack {
                HumidorEnvironmentHistoryView(humidor: humidor)
            }
        }
        .sheet(isPresented: $showEnvironmentReport) {
            NavigationStack {
                EnvironmentReportView(humidor: humidor)
            }
        }
        .task {
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
                // Sync with HomeKit after fetching new data
                await updateHomeKit(
                    temperature: viewModel.temperature,
                    humidity: viewModel.humidity
                )
            }
        }
    }
    
    private func updateHomeKit(temperature: Double?, humidity: Double?) async {
        guard homeKit.isAuthorized else { return }
        
        if let temperature = temperature {
            // Update temperature sensors
            for sensor in homeKit.temperatureSensors {
                do {
                    try await homeKit.updateSensorValue(temperature, for: .temperature, accessory: sensor)
                } catch {
                    logger.error("Failed to update HomeKit temperature sensor: \(error.localizedDescription)")
                }
            }
        }
        
        if let humidity = humidity {
            // Update humidity sensors
            for sensor in homeKit.humiditySensors {
                do {
                    try await homeKit.updateSensorValue(humidity, for: .humidity, accessory: sensor)
                } catch {
                    logger.error("Failed to update HomeKit humidity sensor: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    EnvironmentalMonitoringView(humidor: Humidor())
} 