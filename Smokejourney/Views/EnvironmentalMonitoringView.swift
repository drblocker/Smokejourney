import SwiftUI
import HomeKit
import os.log

struct EnvironmentalMonitoringView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    let humidor: Humidor
    
    var body: some View {
        VStack {
            if let sensorId = humidor.sensorId,
               let sensor = viewModel.sensors.first(where: { $0.id == sensorId }) {
                // Show environmental data
                EnvironmentalDataView(viewModel: viewModel)
            } else {
                // Show prompt to add sensor
                ContentUnavailableView {
                    Label("No Sensor", systemImage: "sensor.fill")
                } description: {
                    Text("Add a sensor to monitor environment")
                } actions: {
                    NavigationLink(destination: SensorSelectionView(humidor: humidor)) {
                        Text("Add Sensor")
                    }
                }
            }
        }
        .task {
            if let sensorId = humidor.sensorId {
                await viewModel.fetchLatestSample(for: sensorId)
            }
        }
    }
}

#Preview {
    EnvironmentalMonitoringView(humidor: Humidor())
} 