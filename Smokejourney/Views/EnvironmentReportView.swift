import SwiftUI
import Charts

struct EnvironmentReportView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    let humidor: Humidor
    
    var body: some View {
        List {
            Section("Daily Summary") {
                HStack {
                    Text("Average Temperature")
                    Spacer()
                    Text(viewModel.dailyAverageTemperature)
                }
                
                HStack {
                    Text("Average Humidity")
                    Spacer()
                    Text(viewModel.dailyAverageHumidity)
                }
            }
            
            Section("Historical Data") {
                VStack {
                    Chart(viewModel.historicalData, id: \.timestamp) { data in
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
                    .frame(height: 200)
                    
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
            
            Section("Alerts") {
                ForEach(viewModel.environmentalAlerts) { alert in
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
        }
        .navigationTitle("Environment Report")
        .task {
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
                await viewModel.loadHistoricalData(sensorId: sensorId)
            }
        }
    }
}

#Preview {
    NavigationStack {
        EnvironmentReportView(humidor: Humidor())
    }
} 