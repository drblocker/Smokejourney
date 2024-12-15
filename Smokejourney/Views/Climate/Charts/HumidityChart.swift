import SwiftUI
import Charts

struct HumidityChart: View {
    @ObservedObject var viewModel: ClimateViewModel
    
    var body: some View {
        ChartCard(title: "Humidity") {
            Chart(viewModel.chartData, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Humidity", sample.humidity)
                )
                .foregroundStyle(Color.blue)
                
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Humidity", sample.humidity)
                )
                .foregroundStyle(Color.blue.opacity(0.1))
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
                    if let humidity = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(humidity))%")
                        }
                    }
                }
            }
            .chartYScale(domain: viewModel.humidityRange)
        }
    }
} 