import Foundation
import SwiftUI
import os.log

@MainActor
final class HumidorEnvironmentViewModel: ObservableObject {
    @Published var historicalData: [(timestamp: Date, temperature: Double, humidity: Double)] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var sensors: [SensorPushDevice] = []
    @Published var temperature: Double?
    @Published var humidity: Double?
    @Published var lastUpdated: Date?
    @Published var temperatureStatus: EnvironmentStatus = .normal
    @Published var humidityStatus: EnvironmentStatus = .normal
    
    // Stability metrics (0.0 to 1.0)
    @Published var temperatureStability: Double = 0.0
    @Published var humidityStability: Double = 0.0
    
    @Published var environmentalAlerts: [EnvironmentalMonitoring.Alert] = []
    
    // Add range and average properties
    @Published var temperatureRange: String = "N/A"
    @Published var humidityRange: String = "N/A"
    @Published var dailyAverageTemperature: String = "N/A"
    @Published var dailyAverageHumidity: String = "N/A"
    
    @Published var isAuthenticated = UserDefaults.standard.bool(forKey: "sensorPushAuthenticated")
    @Published var showAuthenticationSheet = false
    
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "HumidorEnvironment")
    private let sensorPushService = SensorPushService.shared
    private let keychain = KeychainWrapper.standard
    
    private let emailKey = "sensorPushEmail"
    private let passwordKey = "sensorPushPassword"
    
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
        var newAlerts: [EnvironmentalMonitoring.Alert] = []
        
        // Check temperature
        if let temp = temperature {
            let tempLowAlert = UserDefaults.standard.double(forKey: "tempLowAlert")
            let tempHighAlert = UserDefaults.standard.double(forKey: "tempHighAlert")
            
            if temp < tempLowAlert {
                newAlerts.append(EnvironmentalMonitoring.Alert(
                    type: .temperatureLow,
                    message: String(format: "Temperature is too low: %.1f°F", temp),
                    timestamp: Date()
                ))
            } else if temp > tempHighAlert {
                newAlerts.append(EnvironmentalMonitoring.Alert(
                    type: .temperatureHigh,
                    message: String(format: "Temperature is too high: %.1f°F", temp),
                    timestamp: Date()
                ))
            }
        }
        
        // Check humidity
        if let hum = humidity {
            let humidityLowAlert = UserDefaults.standard.double(forKey: "humidityLowAlert")
            let humidityHighAlert = UserDefaults.standard.double(forKey: "humidityHighAlert")
            
            if hum < humidityLowAlert {
                newAlerts.append(EnvironmentalMonitoring.Alert(
                    type: .humidityLow,
                    message: String(format: "Humidity is too low: %.1f%%", hum),
                    timestamp: Date()
                ))
            } else if hum > humidityHighAlert {
                newAlerts.append(EnvironmentalMonitoring.Alert(
                    type: .humidityHigh,
                    message: String(format: "Humidity is too high: %.1f%%", hum),
                    timestamp: Date()
                ))
            }
        }
        
        // Update alerts
        if !newAlerts.isEmpty {
            environmentalAlerts = newAlerts + environmentalAlerts
            // Keep only the last 10 alerts
            if environmentalAlerts.count > 10 {
                environmentalAlerts = Array(environmentalAlerts.prefix(10))
            }
        }
    }
    
    func ensureAuthenticated() async throws {
        if !isAuthenticated {
            logger.debug("Not authenticated, checking for stored credentials")
            
            // Try to get stored credentials
            guard let email = keychain.string(forKey: emailKey),
                  let password = keychain.string(forKey: passwordKey) else {
                logger.debug("No stored credentials found")
                await MainActor.run {
                    showAuthenticationSheet = true
                }
                throw SensorPushError.authenticationFailed(message: "Authentication required")
            }
            
            logger.debug("Found stored credentials, attempting to authenticate")
            try await sensorPushService.authenticate(email: email, password: password)
            
            await MainActor.run {
                isAuthenticated = true
            }
        }
    }
    
    func authenticate(email: String, password: String) async throws {
        do {
            try await sensorPushService.authenticate(email: email, password: password)
            
            // Store credentials securely
            keychain.set(email, forKey: emailKey)
            keychain.set(password, forKey: passwordKey)
            
            await MainActor.run {
                isAuthenticated = true
                showAuthenticationSheet = false
            }
        } catch {
            logger.error("Authentication failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        sensorPushService.signOut()
        keychain.removeObject(forKey: emailKey)
        keychain.removeObject(forKey: passwordKey)
        isAuthenticated = false
    }
    
    func fetchLatestSample(for sensorId: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let samples = try await sensorPushService.getSamples(for: sensorId, limit: 1)
            if let latest = samples.first {
                await MainActor.run {
                    self.temperature = latest.temperature
                    self.humidity = latest.humidity
                    self.lastUpdated = latest.time
                    self.isLoading = false
                    updateEnvironmentStatus()
                    checkForAlerts()
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchSensors() async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            let fetchedSensors = try await sensorPushService.getSensors()
            await MainActor.run {
                self.sensors = fetchedSensors
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            logger.error("Failed to fetch sensors: \(error.localizedDescription)")
        }
    }
    
    func loadHistoricalData(for timeRange: TimeRange = .day, sensorId: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            let samples = try await sensorPushService.getSamples(for: sensorId, limit: timeRange.limit)
            await MainActor.run {
                self.historicalData = samples.map { sample in
                    (timestamp: sample.time,
                     temperature: sample.temperature,
                     humidity: sample.humidity)
                }
                calculateStabilityMetrics()
                calculateStatistics()
                updateEnvironmentStatus()
                checkForAlerts()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            logger.error("Failed to load historical data: \(error.localizedDescription)")
        }
    }
    
    private func updateEnvironmentStatus() {
        // Update temperature status
        if let temp = temperature {
            let tempLowAlert = UserDefaults.standard.double(forKey: "tempLowAlert")
            let tempHighAlert = UserDefaults.standard.double(forKey: "tempHighAlert")
            
            if temp < tempLowAlert || temp > tempHighAlert {
                temperatureStatus = .critical
            } else if abs(temp - ((tempLowAlert + tempHighAlert) / 2)) > 3 {
                temperatureStatus = .warning
            } else {
                temperatureStatus = .normal
            }
        }
        
        // Update humidity status
        if let hum = humidity {
            let humidityLowAlert = UserDefaults.standard.double(forKey: "humidityLowAlert")
            let humidityHighAlert = UserDefaults.standard.double(forKey: "humidityHighAlert")
            
            if hum < humidityLowAlert || hum > humidityHighAlert {
                humidityStatus = .critical
            } else if abs(hum - ((humidityLowAlert + humidityHighAlert) / 2)) > 5 {
                humidityStatus = .warning
            } else {
                humidityStatus = .normal
            }
        }
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
} 
