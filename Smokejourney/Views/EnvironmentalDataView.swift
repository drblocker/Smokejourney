import SwiftUI

struct EnvironmentalDataView: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Temperature Card
            EnvironmentCardView(
                title: "Temperature",
                value: viewModel.temperature.map { String(format: "%.1f°F", $0) } ?? "--°F",
                status: viewModel.temperatureStatus ?? .normal,
                icon: "thermometer"
            )
            
            // Humidity Card
            EnvironmentCardView(
                title: "Humidity",
                value: viewModel.humidity.map { String(format: "%.1f%%", $0) } ?? "--%",
                status: viewModel.humidityStatus ?? .normal,
                icon: "humidity"
            )
            
            // Last Updated
            if let lastUpdated = viewModel.lastUpdated {
                Text("Last Updated: \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    EnvironmentalDataView(viewModel: HumidorEnvironmentViewModel())
} 