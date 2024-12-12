import SwiftUI
import SwiftData
import HomeKit
import Charts

struct ClimateView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var climateSensors: [ClimateSensor]
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @EnvironmentObject private var homeKitManager: HomeKitService
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    @State private var showAddSensor = false
    @State private var selectedTimeRange: TimeRange = .day
    
    var body: some View {
        NavigationStack {
            Group {
                if climateSensors.isEmpty {
                    ContentUnavailableView {
                        Label("No Sensors", systemImage: "sensor.fill")
                    } description: {
                        Text("Add a sensor to monitor climate conditions")
                    } actions: {
                        Button(action: { showAddSensor = true }) {
                            Label("Add Sensor", systemImage: "plus")
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ClimateTimeRangePicker(selectedRange: $selectedTimeRange)
                            CurrentConditionsCard(viewModel: viewModel)
                            EnvironmentChartsSection(viewModel: viewModel, timeRange: selectedTimeRange)
                            StabilityMetricsView(viewModel: viewModel)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Climate")
            .toolbar {
                if !climateSensors.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showAddSensor = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSensor) {
                NavigationStack {
                    SensorSelectionSheet { sensorId, type in
                        if let sensorId = sensorId {
                            let sensor = ClimateSensor(id: sensorId, type: type)
                            modelContext.insert(sensor)
                            try? modelContext.save()
                            showAddSensor = false
                            
                            Task {
                                await refreshData()
                            }
                        }
                    }
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
    
    private func refreshData() async {
        // Only fetch SensorPush sensors if we have any SensorPush climate sensors
        if climateSensors.contains(where: { $0.type == .sensorPush }) {
            await viewModel.fetchSensors()
        }
        
        // Refresh data for each sensor based on its type
        for sensor in climateSensors {
            switch sensor.type {
            case .sensorPush:
                if sensorPushManager.isAuthorized {
                    await viewModel.loadHistoricalData(for: selectedTimeRange, sensorId: sensor.id)
                }
            case .homeKit:
                if homeKitManager.isAuthorized {
                    // Load HomeKit sensor data
                    if let accessory = homeKitManager.temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == sensor.id }) {
                        await viewModel.loadHomeKitData(
                            for: accessory,
                            timeRange: selectedTimeRange
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Time Range Selection
struct ClimateTimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.id) { range in
                Text(range.displayName).tag(range)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Conditions")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                if let temperature = viewModel.currentTemperature {
                    ReadingView(
                        value: String(format: "%.1f°F", temperature),
                        title: "Temperature",
                        icon: "thermometer",
                        color: .orange
                    )
                }
                
                if let humidity = viewModel.currentHumidity {
                    ReadingView(
                        value: String(format: "%.1f%%", humidity),
                        title: "Humidity",
                        icon: "humidity",
                        color: .blue
                    )
                }
            }
            .padding(.horizontal)
        }
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

struct ReadingView: View {
    let value: String
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
} 