import SwiftUI
import Charts

struct TemperatureChart: View {
    @ObservedObject var viewModel: ClimateViewModel
    
    var body: some View {
        ChartCard(title: "Temperature") {
            Chart(viewModel.chartData, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Temperature", sample.temperature)
                )
                .foregroundStyle(Color.orange)
                
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Temperature", sample.temperature)
                )
                .foregroundStyle(Color.orange.opacity(0.1))
            }
            .chartXAxis {
                AxisMarks { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(viewModel.selectedTimeRange.chartXAxisFormat))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let temp = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(temp))°F")
                        }
                    }
                }
            }
            .chartYScale(domain: viewModel.temperatureRange)
        }
    }
} 