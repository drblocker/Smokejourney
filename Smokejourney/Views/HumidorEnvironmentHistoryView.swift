import SwiftUI
import Charts

// MARK: - Data Types
struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
    let humidity: Double
}

// MARK: - Analysis Section View
struct AnalysisSectionView: View {
    let viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            AnalysisRow(
                title: "Temperature Stability",
                value: viewModel.temperatureStability,
                description: "Based on variance over time"
            )
            
            AnalysisRow(
                title: "Humidity Stability",
                value: viewModel.humidityStability,
                description: "Based on variance over time"
            )
            
            if !viewModel.environmentalAlerts.isEmpty {
                Section("Recent Alerts") {
                    ForEach(viewModel.environmentalAlerts) { alert in
                        EnvironmentalAlertRow(alert: alert)
                    }
                }
            }
        }
    }
}

// MARK: - Statistics View
struct EnvironmentStatisticsView: View {
    let viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temperature Range: \(viewModel.temperatureRange)")
            Text("Humidity Range: \(viewModel.humidityRange)")
            Text("Daily Average Temperature: \(viewModel.dailyAverageTemperature)")
            Text("Daily Average Humidity: \(viewModel.dailyAverageHumidity)")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.top, 8)
    }
}

// MARK: - View Models and Types
struct ChartConfiguration {
    var timeRange: TimeRange
    var chartType: ChartType
}

// MARK: - Supporting Views
struct HumidorEnvironmentHistoryView: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedChartType: ChartType = .line
    @State private var selectedDataPoint: DataPoint?
    let sensorId: String
    
    var body: some View {
        VStack(spacing: 16) {
            ChartControls(
                timeRange: $selectedTimeRange,
                chartType: $selectedChartType
            )
            
            ScrollView {
                VStack(spacing: 20) {
                    AnalysisSectionView(viewModel: viewModel)
                    EnvironmentStatisticsView(viewModel: viewModel)
                    
                    // Temperature Chart
                    EnvironmentChartView(
                        title: "Temperature",
                        data: viewModel.historicalData,
                        timeRange: selectedTimeRange,
                        chartType: selectedChartType,
                        valueFormatter: { temp in
                            String(format: "%.1f°F", (temp * 9/5) + 32)
                        },
                        color: .orange
                    )
                    
                    // Humidity Chart
                    EnvironmentChartView(
                        title: "Humidity",
                        data: viewModel.historicalData,
                        timeRange: selectedTimeRange,
                        chartType: selectedChartType,
                        valueFormatter: { humidity in
                            String(format: "%.1f%%", humidity)
                        },
                        color: .blue
                    )
                }
                .padding()
            }
        }
        .onChange(of: selectedTimeRange) { _ in
            Task {
                await viewModel.loadHistoricalData(for: selectedTimeRange, sensorId: sensorId)
            }
        }
        .task {
            await viewModel.loadHistoricalData(for: selectedTimeRange, sensorId: sensorId)
        }
    }
}

struct EnvironmentChartView: View {
    let title: String
    let data: [(timestamp: Date, temperature: Double, humidity: Double)]
    let timeRange: TimeRange
    let chartType: ChartType
    let valueFormatter: (Double) -> String
    let color: Color
    @State private var selectedDataPoint: DataPoint?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.timestamp) { sample in
                    switch chartType {
                    case .line:
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value(title, sample.temperature)
                        )
                        .foregroundStyle(color)
                        
                        AreaMark(
                            x: .value("Time", sample.timestamp),
                            y: .value(title, sample.temperature)
                        )
                        .foregroundStyle(color.opacity(0.1))
                        
                    case .scatter:
                        PointMark(
                            x: .value("Time", sample.timestamp),
                            y: .value(title, sample.temperature)
                        )
                        .foregroundStyle(color)
                        
                    case .bar:
                        BarMark(
                            x: .value("Time", sample.timestamp),
                            y: .value(title, sample.temperature)
                        )
                        .foregroundStyle(color)
                    }
                }
                
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.timestamp))
                        .annotation(position: .top) {
                            ChartAnnotation(
                                timestamp: selected.timestamp,
                                value: selected.temperature,
                                timeRange: timeRange,
                                valueFormatter: valueFormatter,
                                color: color
                            )
                        }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(timeRange.chartXAxisFormat))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartOverlay { proxy in
                ChartOverlayView(
                    proxy: proxy,
                    selectedDataPoint: $selectedDataPoint,
                    data: data
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Analysis Components
struct AnalysisRow: View {
    let title: String
    let value: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            HStack {
                StabilityIndicator(value: value)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StabilityIndicator: View {
    let value: Double
    
    var color: Color {
        switch value {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
    }
}

struct EnvironmentalAlertRow: View {
    let alert: EnvironmentAlert
    
    var body: some View {
        HStack {
            Image(systemName: alert.type.icon)
                .foregroundColor(alert.type.color)
            VStack(alignment: .leading) {
                Text(alert.message)
                    .font(.subheadline)
                Text(alert.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChartAnnotation: View {
    let timestamp: Date
    let value: Double
    let timeRange: TimeRange
    let valueFormatter: (Double) -> String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(timestamp.formatted(timeRange.dateFormat))
            Text(valueFormatter(value))
                .foregroundStyle(color)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct ChartOverlayView: View {
    let proxy: ChartProxy
    @Binding var selectedDataPoint: DataPoint?
    let data: [(timestamp: Date, temperature: Double, humidity: Double)]
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                            guard let timestamp = proxy.value(atX: x, as: Date.self) else { return }
                            
                            let closestDataPoint = data
                                .min(by: { abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp)) })
                            
                            if let point = closestDataPoint {
                                selectedDataPoint = DataPoint(
                                    timestamp: point.timestamp,
                                    temperature: point.temperature,
                                    humidity: point.humidity
                                )
                            }
                        }
                        .onEnded { _ in
                            selectedDataPoint = nil
                        }
                )
        }
    }
}

#Preview {
    let viewModel = HumidorEnvironmentViewModel()
    return HumidorEnvironmentHistoryView(viewModel: viewModel, sensorId: "preview-sensor")
} 