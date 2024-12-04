import SwiftUI

struct EnvironmentalDataView: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Temperature Card
            EnvironmentCardView(
                title: "Temperature",
                value: "\(viewModel.temperature?.formatted(.number.precision(.fractionLength(1))) ?? "--")°F",
                status: viewModel.temperatureStatus,
                icon: "thermometer"
            )
            
            // Humidity Card
            EnvironmentCardView(
                title: "Humidity",
                value: "\(viewModel.humidity?.formatted(.number.precision(.fractionLength(1))) ?? "--%")%",
                status: viewModel.humidityStatus,
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