import SwiftUI

struct StabilityMetricsView: View {
    @ObservedObject var viewModel: ClimateViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment Stability")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StabilityGauge(
                    value: viewModel.stabilityMetrics.temperature,
                    title: "Temperature",
                    icon: "thermometer",
                    color: .orange
                )
                
                StabilityGauge(
                    value: viewModel.stabilityMetrics.humidity,
                    title: "Humidity",
                    icon: "humidity",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
    }
}

private struct StabilityGauge: View {
    let value: Double
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Gauge(value: value) {
                Image(systemName: icon)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)
            .scaleEffect(1.5)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
} 