import Foundation
import BackgroundTasks
import UserNotifications
import os.log
import SwiftUI
import SwiftData

@MainActor
final class BackgroundTaskHandler {
    static let shared: BackgroundTaskHandler = {
        guard let modelContainer = try? ModelContainer(for: ClimateSensor.self) else {
            fatalError("Failed to create model container for BackgroundTaskHandler")
        }
        return BackgroundTaskHandler(modelContext: modelContainer.mainContext)
    }()
    
    static let taskIdentifier = "com.smokejourney.sync"
    private var isRegistered = false
    private let logger = Logger(subsystem: "com.smokejourney", category: "BackgroundTask")
    private let sensorManager: SensorManager
    private let modelContext: ModelContext
    private let sensorPushService = SensorPushService.shared
    private var lastSuccessfulSync: Date?
    private var failedAttempts = 0
    private let maxFailedAttempts = 3
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.sensorManager = SensorManager()
        setupBackgroundTasks()
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        Task {
            try? await refreshSensorData()
            scheduleBackgroundTask()
        }
    }
    
    @objc private func appDidEnterBackground() {
        scheduleBackgroundTask() // Ensure task is scheduled when going to background
    }
    
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
        isRegistered = true
        scheduleBackgroundTask()
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = BlockOperation {
            Task { [weak self] in
                do {
                    try await self?.refreshSensorData()
                    task.setTaskCompleted(success: true)
                    await self?.scheduleBackgroundTask()
                } catch {
                    self?.logger.error("Background sensor sync failed: \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }
        }
        
        queue.addOperation(operation)
    }
    
    private func refreshSensorData() async throws {
        for sensor in sensorManager.sensors {
            try await sensor.fetchCurrentReading()
            let historicalData = try await sensor.fetchHistoricalData(timeRange: .day)
            sensorManager.updateReadings(for: sensor.id, with: historicalData)
            
            // Check environmental conditions for each reading
            if let reading = historicalData.last {
                await checkEnvironmentalConditions(reading)
            }
        }
        
        lastSuccessfulSync = Date()
        failedAttempts = 0
    }
    
    private func checkEnvironmentalConditions(_ reading: SensorKit.SensorReading) async {
        let temperature = reading.temperature
        let humidity = reading.humidity
        
        // Check temperature thresholds
        let tempLowAlert = UserDefaults.standard.double(forKey: "tempLowAlert")
        let tempHighAlert = UserDefaults.standard.double(forKey: "tempHighAlert")
        
        if temperature < tempLowAlert || temperature > tempHighAlert {
            await scheduleTemperatureAlert(temperature: temperature)
        }
        
        // Check humidity thresholds
        let humidityLowAlert = UserDefaults.standard.double(forKey: "humidityLowAlert")
        let humidityHighAlert = UserDefaults.standard.double(forKey: "humidityHighAlert")
        
        if humidity < humidityLowAlert || humidity > humidityHighAlert {
            await scheduleHumidityAlert(humidity: humidity)
        }
    }
    
    private func handleSyncFailure(error: Error) {
        failedAttempts += 1
        
        if failedAttempts >= maxFailedAttempts {
            // Schedule retry with exponential backoff
            let delay = pow(2.0, Double(failedAttempts)) * 60 // Exponential backoff in minutes
            scheduleBackgroundTask(withDelay: delay)
            
            // Notify user of sync issues
            Task {
                await notifyUserOfSyncIssues()
            }
        }
    }
    
    private func notifyUserOfSyncIssues() async {
        let content = UNMutableNotificationContent()
        content.title = "Sync Issues"
        content.body = "Unable to sync sensor data. Please check your connection and sensor status."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("Failed to schedule sync issue notification: \(error.localizedDescription)")
        }
    }
    
    private func scheduleBackgroundTask(withDelay delay: TimeInterval = 900) { // Default 15 minutes
        guard isRegistered else {
            logger.error("Attempted to schedule task before registration")
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: delay)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("Scheduled background task with delay: \(delay) seconds")
        } catch {
            logger.error("Failed to schedule background task: \(error.localizedDescription)")
        }
    }
    
    private func scheduleTemperatureAlert(temperature: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Temperature Alert"
        content.body = String(format: "Temperature is %.1f°F", temperature)
        content.sound = .default
        content.categoryIdentifier = "TEMPERATURE_ALERT"
        
        // Add custom data
        content.userInfo = [
            "type": "temperature",
            "value": temperature
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.debug("Scheduled temperature alert for \(temperature)°F")
        } catch {
            logger.error("Failed to schedule temperature alert: \(error.localizedDescription)")
        }
    }
    
    private func scheduleHumidityAlert(humidity: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Humidity Alert"
        content.body = String(format: "Humidity is %.1f%%", humidity)
        content.sound = .default
        content.categoryIdentifier = "HUMIDITY_ALERT"
        
        // Add custom data
        content.userInfo = [
            "type": "humidity",
            "value": humidity
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.debug("Scheduled humidity alert for \(humidity)%")
        } catch {
            logger.error("Failed to schedule humidity alert: \(error.localizedDescription)")
        }
    }
} 