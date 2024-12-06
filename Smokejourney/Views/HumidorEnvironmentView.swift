import SwiftUI

struct HumidorEnvironmentView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @Bindable var humidor: Humidor
    @State private var showSensorSelection = false
    
    var body: some View {
        VStack {
            if let sensorId = humidor.sensorId {
                // Show environmental data
                EnvironmentalDataView(viewModel: viewModel)
            } else {
                // Show prompt to add sensor
                ContentUnavailableView {
                    Label("No Sensor", systemImage: "sensor.fill")
                } description: {
                    Text("Add a sensor to monitor environment")
                } actions: {
                    Button(action: { showSensorSelection = true }) {
                        Text("Add Sensor")
                    }
                }
            }
        }
        .sheet(isPresented: $showSensorSelection) {
            NavigationStack {
                SensorSelectionView(selectedSensorId: $humidor.sensorId)
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
    HumidorEnvironmentView(humidor: Humidor())
} 