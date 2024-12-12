import SwiftUI
import SwiftData
import HomeKit
import Charts

struct ClimateView: View {
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @EnvironmentObject private var homeKitManager: HomeKitService
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showAddSensor = false
    @State private var selectedTimeRange: TimeRange = .day
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ClimateTimeRangePicker(selectedRange: $selectedTimeRange)
                    CurrentConditionsCard(viewModel: viewModel)
                    EnvironmentChartsSection(viewModel: viewModel, timeRange: selectedTimeRange)
                    StabilityMetricsView(viewModel: viewModel)
                }
                .padding(.vertical)
            }
            .navigationTitle("Climate")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSensor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await refreshData()
            }
            .onChange(of: selectedTimeRange) { _ in
                Task {
                    await refreshData()
                }
            }
        }
    }
    
    private func refreshData() async {
        await viewModel.fetchSensors()
        for sensor in sensorPushManager.sensors {
            await viewModel.loadHistoricalData(for: selectedTimeRange, sensorId: sensor.id)
        }
    }
}

// MARK: - Time Range Selection
struct ClimateTimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Charts Section
struct EnvironmentChartsSection: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment History")
                .font(.headline)
                .padding(.horizontal)
            
            TemperatureChart(data: viewModel.historicalData, timeRange: timeRange)
            HumidityChart(data: viewModel.historicalData, timeRange: timeRange)
        }
    }
}

struct TemperatureChart: View {
    let data: [(timestamp: Date, temperature: Double, humidity: Double)]
    let timeRange: TimeRange
    
    var body: some View {
        ChartCard(title: "Temperature") {
            Chart(data, id: \.timestamp) { sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Temperature", (sample.temperature * 9/5) + 32)
                )
                .foregroundStyle(Color.orange)
                
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Temperature", (sample.temperature * 9/5) + 32)
                )
                .foregroundStyle(Color.orange.opacity(0.1))
            }
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
        }
    }
}

struct HumidityChart: View {
    let data: [(timestamp: Date, temperature: Double, humidity: Double)]
    let timeRange: TimeRange
    
    var body: some View {
        ChartCard(title: "Humidity") {
            Chart(data, id: \.timestamp) { sample in
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
                            Text(date.formatted(timeRange.chartXAxisFormat))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// Supporting Views
struct CurrentConditionsCard: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Current Conditions")
                .font(.headline)
            
            HStack(spacing: 30) {
                // Temperature Reading
                VStack {
                    Image(systemName: "thermometer")
                        .font(.title)
                        .foregroundStyle(.orange)
                    if let temp = viewModel.temperature {
                        Text(String(format: "%.1f°F", (temp * 9/5) + 32))
                            .font(.title2)
                        Text("Temperature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Humidity Reading
                VStack {
                    Image(systemName: "humidity")
                        .font(.title)
                        .foregroundStyle(.blue)
                    if let humidity = viewModel.humidity {
                        Text(String(format: "%.1f%%", humidity))
                            .font(.title2)
                        Text("Humidity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let updated = viewModel.lastUpdated {
                Text("Updated \(updated.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            content()
                .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StabilityMetricsView: View {
    @ObservedObject var viewModel: HumidorEnvironmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment Stability")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StabilityGauge(
                    value: viewModel.temperatureStability,
                    title: "Temperature",
                    icon: "thermometer",
                    color: .orange
                )
                
                StabilityGauge(
                    value: viewModel.humidityStability,
                    title: "Humidity",
                    icon: "humidity",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StabilityGauge: View {
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