import SwiftUI

struct EnvironmentChartsSection: View {
    @ObservedObject var viewModel: ClimateViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment History")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.chartData.isEmpty {
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.line.downtrend.xyaxis")
                } description: {
                    Text("Waiting for sensor readings")
                }
                .frame(height: 200)
            } else {
                TemperatureChart(viewModel: viewModel)
                HumidityChart(viewModel: viewModel)
            }
        }
    }
} 