import SwiftUI
import SwiftData

struct EnvironmentalMonitoringTabView: View {
    @Query private var humidors: [Humidor]
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Overall Status Section
                Section {
                    ForEach(humidors) { humidor in
                        if let sensorId = humidor.sensorId {
                            HumidorEnvironmentCard(humidor: humidor, viewModel: viewModel)
                        }
                    }
                    
                    if !humidors.contains(where: { $0.sensorId != nil }) {
                        ContentUnavailableView {
                            Label("No Sensors Connected", systemImage: "sensor.fill")
                        } description: {
                            Text("Add a sensor to any humidor to monitor its environment")
                        }
                    }
                }
                
                // Alerts Section
                if !viewModel.environmentalAlerts.isEmpty {
                    Section("Recent Alerts") {
                        ForEach(viewModel.environmentalAlerts) { alert in
                            AlertRow(alert: alert)
                        }
                    }
                }
                
                // Management Section
                Section("Management") {
                    NavigationLink(destination: SensorManagementView()) {
                        Label("Manage Sensors", systemImage: "sensor.fill")
                    }
                    
                    NavigationLink(destination: HumidorAlertSettingsView()) {
                        Label("Alert Settings", systemImage: "bell.badge")
                    }
                }
            }
            .navigationTitle("Environment")
            .refreshable {
                // Refresh all connected sensors
                for humidor in humidors where humidor.sensorId != nil {
                    await viewModel.fetchLatestSample(for: humidor.sensorId!)
                }
            }
        }
    }
}

struct HumidorEnvironmentCard: View {
    let humidor: Humidor
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Humidor Name
            Text(humidor.effectiveName)
                .font(.headline)
            
            // Current Readings
            HStack(spacing: 20) {
                EnvironmentReadingView(
                    title: "Temperature",
                    value: viewModel.temperature.map { String(format: "%.1f°F", $0) } ?? "--°F",
                    status: viewModel.temperatureStatus
                )
                
                EnvironmentReadingView(
                    title: "Humidity",
                    value: viewModel.humidity.map { String(format: "%.1f%%", $0) } ?? "--%",
                    status: viewModel.humidityStatus
                )
            }
            
            // Last Updated
            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .task {
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
            }
        }
    }
}

struct EnvironmentReadingView: View {
    let title: String
    let value: String
    let status: EnvironmentStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text(value)
                    .font(.title3)
                    .bold()
                Image(systemName: status.icon)
            }
            .foregroundColor(status.color)
        }
    }
}

struct AlertRow: View {
    let alert: EnvironmentalMonitoring.Alert
    
    var body: some View {
        HStack {
            Image(systemName: alert.type.icon)
                .foregroundColor(alert.type.color)
            VStack(alignment: .leading) {
                Text(alert.message)
                Text(alert.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    EnvironmentalMonitoringTabView()
}
