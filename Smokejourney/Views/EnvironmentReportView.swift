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
            await viewModel.fetchLatestData()
        }
    }
} 