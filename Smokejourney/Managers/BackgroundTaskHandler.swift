import Foundation
import BackgroundTasks
import UserNotifications
import os.log
import SwiftUI

@MainActor
final class BackgroundTaskHandler {
    static let shared = BackgroundTaskHandler()
    static let taskIdentifier = "com.jason.smokejourney.sync"
    private var isRegistered = false
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "BackgroundTask")
    private let sensorPushService = SensorPushService.shared
    private let environmentViewModel = HumidorEnvironmentViewModel()
    private var lastSuccessfulSync: Date?
    private var failedAttempts = 0
    private let maxFailedAttempts = 3
    
    private init() {
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
            if let sensor = await environmentViewModel.sensors.first {
                await environmentViewModel.fetchLatestSample(for: sensor.id)
            }
            scheduleBackgroundTask() // Reschedule after coming to foreground
        }
    }
    
    @objc private func appDidEnterBackground() {
        scheduleBackgroundTask() // Ensure task is scheduled when going to background
    }
    
    private func refreshSensorData() async {
        guard UserDefaults.standard.bool(forKey: "sensorPushAuthenticated") else {
            logger.debug("Skipping sensor refresh - not authenticated")
            return
        }
        
        do {
            let sensors = try await sensorPushService.getSensors()
            for sensor in sensors {
                await environmentViewModel.fetchLatestSample(for: sensor.id)
                let samples = try await sensorPushService.getSamples(for: sensor.id, limit: 1)
                if let latestSample = samples.first {
                    await checkEnvironmentalConditions(latestSample)
                }
                logger.debug("Successfully fetched data for sensor: \(sensor.id)")
            }
            lastSuccessfulSync = Date()
            failedAttempts = 0
        } catch {
            logger.error("Failed to refresh sensor data: \(error.localizedDescription)")
            handleSyncFailure(error: error)
        }
    }
    
    func setupBackgroundTasks() {
        registerBackgroundTask()
        setupNotifications()
        scheduleBackgroundTask() // Initial schedule
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                self.logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    private func registerBackgroundTask() {
        guard !isRegistered else {
            logger.debug("Background task already registered")
            return
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
        isRegistered = true
        logger.debug("Successfully registered background task")
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        logger.debug("Starting background task")
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        task.expirationHandler = { [weak self] in
            queue.cancelAllOperations()
            self?.logger.error("Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        let operation = BlockOperation {
            Task { [weak self] in
                do {
                    try await self?.performSensorSync()
                    task.setTaskCompleted(success: true)
                    self?.logger.debug("Background sensor sync completed successfully")
                    await self?.scheduleBackgroundTask()
                } catch {
                    self?.logger.error("Background sensor sync failed: \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }
        }
        
        queue.addOperation(operation)
    }
    
    private func performSensorSync() async throws {
        let sensors = try await sensorPushService.getSensors()
        guard let firstSensor = sensors.first else {
            logger.debug("No sensors available")
            return
        }
        
        let samples = try await sensorPushService.getSamples(for: firstSensor.id, limit: 1)
        if let latestSample = samples.first {
            await checkEnvironmentalConditions(latestSample)
            await environmentViewModel.fetchLatestSample(for: firstSensor.id)
            lastSuccessfulSync = Date()
            failedAttempts = 0
        }
    }
    
    private func checkEnvironmentalConditions(_ sample: SensorSample) async {
        let temperature = sample.temperature
        let humidity = sample.humidity
        
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