import SwiftUI
import Charts

// MARK: - Data Types
struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
    let humidity: Double
}

enum ChartType: String, CaseIterable {
    case line = "Line"
    case scatter = "Scatter"
    case bar = "Bar"
    
    var icon: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .scatter: return "chart.scatter"
        case .bar: return "chart.bar"
        }
    }
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

struct HumidorEnvironmentHistoryView: View {
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    let humidor: Humidor
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedDataPoint: DataPoint?
    @State private var chartType: ChartType = .line
    
    var body: some View {
        List {
            // Time Range and Chart Type Selection
            Section {
                TimeRangeSelectionView(
                    selectedTimeRange: $selectedTimeRange,
                    chartType: $chartType
                )
            }
            
            // Temperature Chart
            Section("Temperature History") {
                TemperatureChartView(
                    viewModel: viewModel,
                    chartType: chartType,
                    selectedDataPoint: $selectedDataPoint,
                    selectedTimeRange: selectedTimeRange
                )
            }
            
            // Analysis Section
            Section("Analysis") {
                AnalysisSectionView(viewModel: viewModel)
            }
        }
        .navigationTitle("Environment History")
        .onChange(of: selectedTimeRange) {
            Task {
                await viewModel.loadHistoricalData(for: selectedTimeRange)
            }
        }
        .task {
            await viewModel.loadHistoricalData(for: selectedTimeRange)
        }
    }
}

// MARK: - Supporting Views
struct TimeRangeSelectionView: View {
    @Binding var selectedTimeRange: TimeRange
    @Binding var chartType: ChartType
    
    var body: some View {
        HStack {
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Chart Type", selection: $chartType) {
                Image(systemName: "chart.line.uptrend.xyaxis").tag(ChartType.line)
                Image(systemName: "chart.scatter").tag(ChartType.scatter)
                Image(systemName: "chart.bar").tag(ChartType.bar)
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 8)
    }
}

struct TemperatureChartView: View {
    let viewModel: HumidorEnvironmentViewModel
    let chartType: ChartType
    @Binding var selectedDataPoint: DataPoint?
    let selectedTimeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading) {
            Chart {
                ForEach(viewModel.historicalData, id: \.timestamp) { dataPoint in
                    switch chartType {
                    case .line:
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Temperature", dataPoint.temperature)
                        )
                        .foregroundStyle(.red.gradient)
                        .interpolationMethod(.catmullRom)
                    case .scatter:
                        PointMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Temperature", dataPoint.temperature)
                        )
                        .foregroundStyle(.red)
                    case .bar:
                        BarMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Temperature", dataPoint.temperature)
                        )
                        .foregroundStyle(.red.gradient)
                    }
                }
                
                if let selected = selectedDataPoint {
                    RuleMark(
                        x: .value("Selected", selected.timestamp)
                    )
                    .foregroundStyle(.gray.opacity(0.3))
                    .annotation(position: .top) {
                        DataPointAnnotation(temperature: selected.temperature)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedTimeRange.strideBy)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: selectedTimeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let temp = value.as(Double.self) {
                            Text("\(temp, format: .number)°F")
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                ChartOverlayView(proxy: proxy, selectedDataPoint: $selectedDataPoint, data: viewModel.historicalData)
            }
            .frame(height: 200)
            
            if !viewModel.historicalData.isEmpty {
                EnvironmentStatisticsView(viewModel: viewModel)
            }
        }
    }
}

struct DataPointAnnotation: View {
    let temperature: Double
    
    var body: some View {
        VStack {
            Text("\(temperature, format: .number.precision(.fractionLength(1)))°F")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .cornerRadius(4)
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

#Preview {
    NavigationStack {
        HumidorEnvironmentHistoryView(humidor: Humidor())
    }
} 