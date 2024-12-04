import Foundation
import SwiftUI
import os.log

@MainActor
class HumidorEnvironmentViewModel: ObservableObject {
    @Published var historicalData: [(timestamp: Date, temperature: Double, humidity: Double)] = []
    @Published var temperatureRange: String = "N/A"
    @Published var humidityRange: String = "N/A"
    @Published var dailyAverageTemperature: String = "N/A"
    @Published var dailyAverageHumidity: String = "N/A"
    @Published var environmentalAlerts: [EnvironmentalMonitoring.Alert] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Stability metrics (0.0 to 1.0)
    @Published var temperatureStability: Double = 0.0
    @Published var humidityStability: Double = 0.0
    
    @Published var temperature: Double?
    @Published var humidity: Double?
    @Published var temperatureStatus: EnvironmentalMonitoring.Status = .normal
    @Published var humidityStatus: EnvironmentalMonitoring.Status = .normal
    @Published var lastUpdated: Date?
    @Published var sensors: [Sensor] = []
    
    private let sensorPushService = SensorPushService.shared
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "HumidorEnvironment")
    
    func loadHistoricalData(for timeRange: TimeRange) async {
        isLoading = true
        error = nil
        
        do {
            let samples = try await sensorPushService.getSamples(limit: timeRange.limit)
            
            // Process and store the data
            historicalData = samples.map { sample in
                (timestamp: sample.timestamp,
                 temperature: sample.temperature,
                 humidity: sample.humidity)
            }
            
            // Calculate statistics
            calculateStatistics()
            calculateStabilityMetrics()
            checkForAlerts()
            
        } catch {
            self.error = "Failed to load historical data: \(error.localizedDescription)"
            logger.error("Failed to load historical data: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func calculateStatistics() {
        guard !historicalData.isEmpty else { return }
        
        // Temperature statistics
        let temperatures = historicalData.map { $0.temperature }
        let minTemp = temperatures.min() ?? 0
        let maxTemp = temperatures.max() ?? 0
        let avgTemp = temperatures.reduce(0, +) / Double(temperatures.count)
        
        // Humidity statistics
        let humidities = historicalData.map { $0.humidity }
        let minHumidity = humidities.min() ?? 0
        let maxHumidity = humidities.max() ?? 0
        let avgHumidity = humidities.reduce(0, +) / Double(humidities.count)
        
        // Update published properties
        temperatureRange = String(format: "%.1f°F - %.1f°F", minTemp, maxTemp)
        humidityRange = String(format: "%.1f%% - %.1f%%", minHumidity, maxHumidity)
        dailyAverageTemperature = String(format: "%.1f°F", avgTemp)
        dailyAverageHumidity = String(format: "%.1f%%", avgHumidity)
    }
    
    private func calculateStabilityMetrics() {
        guard !historicalData.isEmpty else { return }
        
        // Calculate temperature stability
        let temperatures = historicalData.map { $0.temperature }
        let tempVariance = calculateVariance(temperatures)
        temperatureStability = max(0, min(1, 1 - (tempVariance / 10)))
        
        // Calculate humidity stability
        let humidities = historicalData.map { $0.humidity }
        let humidityVariance = calculateVariance(humidities)
        humidityStability = max(0, min(1, 1 - (humidityVariance / 10)))
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func checkForAlerts() {
        guard let latestData = historicalData.first else { return }
        
        let tempLowAlert = UserDefaults.standard.double(forKey: "tempLowAlert")
        let tempHighAlert = UserDefaults.standard.double(forKey: "tempHighAlert")
        let humidityLowAlert = UserDefaults.standard.double(forKey: "humidityLowAlert")
        let humidityHighAlert = UserDefaults.standard.double(forKey: "humidityHighAlert")
        
        // Check temperature
        if latestData.temperature < tempLowAlert {
            addAlert(.temperatureLow, message: "Temperature below minimum threshold")
        } else if latestData.temperature > tempHighAlert {
            addAlert(.temperatureHigh, message: "Temperature above maximum threshold")
        }
        
        // Check humidity
        if latestData.humidity < humidityLowAlert {
            addAlert(.humidityLow, message: "Humidity below minimum threshold")
        } else if latestData.humidity > humidityHighAlert {
            addAlert(.humidityHigh, message: "Humidity above maximum threshold")
        }
    }
    
    private func addAlert(_ type: EnvironmentalMonitoring.AlertType, message: String) {
        let alert = EnvironmentalMonitoring.Alert(
            type: type,
            message: message,
            timestamp: Date()
        )
        environmentalAlerts.append(alert)
    }
    
    func fetchLatestData() async {
        isLoading = true
        do {
            let samples = try await sensorPushService.getSamples(limit: 1)
            if let latest = samples.first {
                await MainActor.run {
                    self.temperature = latest.temperature
                    self.humidity = latest.humidity
                    self.lastUpdated = latest.timestamp
                    updateEnvironmentStatus()
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchLatestSample(for sensorId: String) async {
        do {
            let samples = try await sensorPushService.getSamples(limit: 1)
            if let latest = samples.first {
                await MainActor.run {
                    self.temperature = latest.temperature
                    self.humidity = latest.humidity
                    self.lastUpdated = latest.timestamp
                    updateEnvironmentStatus()
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchSensors() async {
        do {
            let fetchedSensors = try await sensorPushService.getSensors()
            await MainActor.run {
                self.sensors = fetchedSensors
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func updateEnvironmentStatus() {
        // Update temperature status
        if let temp = temperature {
            if temp < UserDefaults.standard.double(forKey: "tempLowAlert") {
                temperatureStatus = .critical
            } else if temp > UserDefaults.standard.double(forKey: "tempHighAlert") {
                temperatureStatus = .critical
            } else {
                temperatureStatus = .normal
            }
        }
        
        // Update humidity status
        if let hum = humidity {
            if hum < UserDefaults.standard.double(forKey: "humidityLowAlert") {
                humidityStatus = .critical
            } else if hum > UserDefaults.standard.double(forKey: "humidityHighAlert") {
                humidityStatus = .critical
            } else {
                humidityStatus = .normal
            }
        }
    }
} 