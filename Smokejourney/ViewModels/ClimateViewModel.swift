import SwiftUI
import SwiftData
import SensorKit

@MainActor
class ClimateViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var alerts: [EnvironmentalAlert] = []
    @Published var selectedTimeRange: TimeRange = .day
    
    private let modelContext: ModelContext
    private let sensorManager: SensorManager
    private var updateTask: Task<Void, Never>?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.sensorManager = SensorManager()
        startPeriodicUpdates()
    }
    
    private func startPeriodicUpdates() {
        updateTask?.cancel()
        updateTask = Task {
            while !Task.isCancelled {
                await refreshData()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }
    
    func refreshData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            for sensor in sensorManager.sensors {
                try await sensor.fetchCurrentReading()
                let historicalData = try await sensor.fetchHistoricalData(timeRange: selectedTimeRange)
                sensorManager.updateReadings(for: sensor.id, with: historicalData)
            }
            checkAlerts()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadSensorData(for sensor: ClimateSensor) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let environmentalSensor: any EnvironmentalSensor
            switch sensor.type {
            case .homeKit:
                if let accessory = HomeKitService.shared.temperatureSensors
                    .first(where: { $0.uniqueIdentifier.uuidString == sensor.id }) {
                    environmentalSensor = HomeKitSensor(accessory: accessory)
                } else {
                    throw SensorError.notFound
                }
            case .sensorPush:
                if let device = SensorPushService.shared.sensors
                    .first(where: { $0.id == sensor.id }) {
                    environmentalSensor = SensorPushSensor(device: device)
                } else {
                    throw SensorError.notFound
                }
            }
            
            sensorManager.addSensor(environmentalSensor)
            await refreshData()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func checkAlerts() {
        var newAlerts: [EnvironmentalAlert] = []
        
        for sensor in sensorManager.sensors {
            if let temp = sensor.currentTemperature {
                let tempLowAlert = UserDefaults.standard.double(forKey: "tempLowAlert")
                let tempHighAlert = UserDefaults.standard.double(forKey: "tempHighAlert")
                
                if temp < tempLowAlert {
                    newAlerts.append(.temperatureLow(sensorId: sensor.id, value: temp))
                } else if temp > tempHighAlert {
                    newAlerts.append(.temperatureHigh(sensorId: sensor.id, value: temp))
                }
            }
            
            if let humidity = sensor.currentHumidity {
                let humidityLowAlert = UserDefaults.standard.double(forKey: "humidityLowAlert")
                let humidityHighAlert = UserDefaults.standard.double(forKey: "humidityHighAlert")
                
                if humidity < humidityLowAlert {
                    newAlerts.append(.humidityLow(sensorId: sensor.id, value: humidity))
                } else if humidity > humidityHighAlert {
                    newAlerts.append(.humidityHigh(sensorId: sensor.id, value: humidity))
                }
            }
        }
        
        alerts = newAlerts
    }
    
    // MARK: - Computed Properties
    var hasAnySensors: Bool {
        !sensorManager.sensors.isEmpty
    }
    
    var averageTemperature: Double? {
        let temps = sensorManager.sensors.compactMap(\.currentTemperature)
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }
    
    var averageHumidity: Double? {
        let humidities = sensorManager.sensors.compactMap(\.currentHumidity)
        guard !humidities.isEmpty else { return nil }
        return humidities.reduce(0, +) / Double(humidities.count)
    }
    
    var chartData: [(timestamp: Date, temperature: Double, humidity: Double)] {
        sensorManager.readings.values.map { reading in
            (timestamp: reading.timestamp,
             temperature: reading.temperature,
             humidity: reading.humidity)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    var temperatureRange: ClosedRange<Double> {
        let temps = chartData.map(\.temperature)
        guard let min = temps.min(), let max = temps.max() else { return 0...100 }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var humidityRange: ClosedRange<Double> {
        let humidities = chartData.map(\.humidity)
        guard let min = humidities.min(), let max = humidities.max() else { return 0...100 }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var stabilityMetrics: StabilityMetrics {
        let tempVariance = calculateVariance(chartData.map(\.temperature))
        let humidityVariance = calculateVariance(chartData.map(\.humidity))
        
        let tempStability = max(0, min(1, 1 - (tempVariance / 5)))  // 5°F variance = 0 stability
        let humidityStability = max(0, min(1, 1 - (humidityVariance / 10))) // 10% variance = 0 stability
        
        return StabilityMetrics(temperature: tempStability, humidity: humidityStability)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    func isSensorActive(_ sensor: ClimateSensor) -> Bool {
        sensorManager.sensors.contains { $0.id == sensor.id }
    }
    
    func removeSensor(_ sensorId: String) {
        sensorManager.removeSensor(sensorId)
    }
    
    deinit {
        updateTask?.cancel()
    }
} 