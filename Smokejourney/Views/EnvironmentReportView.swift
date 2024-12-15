import SwiftUI
import SwiftData
import Charts

struct EnvironmentReportView: View {
    @ObservedObject var viewModel: ClimateViewModel
    
    var body: some View {
        List {
            Section {
                if let temp = viewModel.averageTemperature {
                    LabeledContent("Temperature") {
                        Text(String(format: "%.1f°F", temp))
                    }
                }
                
                if let humidity = viewModel.averageHumidity {
                    LabeledContent("Humidity") {
                        Text(String(format: "%.1f%%", humidity))
                    }
                }
            } header: {
                Text("Current Conditions")
            }
            
            Section {
                Chart(viewModel.chartData, id: \.timestamp) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Temperature", reading.temperature)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 200)
            } header: {
                Text("Temperature History")
            }
            
            Section {
                Chart(viewModel.chartData, id: \.timestamp) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Humidity", reading.humidity)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
            } header: {
                Text("Humidity History")
            }
        }
        .navigationTitle("Environment Report")
    }
}

#Preview {
    NavigationStack {
        EnvironmentReportView(viewModel: ClimateViewModel(modelContext: try! ModelContainer(for: Sensor.self).mainContext))
    }
} 