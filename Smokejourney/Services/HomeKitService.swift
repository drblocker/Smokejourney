import HomeKit
import os.log
import UserNotifications
import SwiftUI

// MARK: - Error Types
enum HomeKitServiceError: LocalizedError {
    case homeNotFound
    case characteristicNotFound
    case authorizationFailed
    case actionSetUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .homeNotFound:
            return "No HomeKit home found"
        case .characteristicNotFound:
            return "Required characteristic not found"
        case .authorizationFailed:
            return "HomeKit authorization failed"
        case .actionSetUpdateFailed:
            return "Failed to update action set"
        }
    }
}

// MARK: - Main Service Class
@MainActor
final class HomeKitService: NSObject, ObservableObject {
    static let shared = HomeKitService()
    private let logger = Logger(subsystem: "com.smokejourney", category: "HomeKitService")
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var currentHome: HMHome?
    @Published private(set) var temperatureSensors: [HMAccessory] = []
    @Published private(set) var humiditySensors: [HMAccessory] = []
    @Published private(set) var authorizationStatus: HMHomeManagerAuthorizationStatus = .determined
    @Published private(set) var isInitialized = false
    
    private let homeManager: HMHomeManager
    
    // MARK: - Types
    enum SensorType: String, CaseIterable {
        case temperature = "Temperature"
        case humidity = "Humidity"
        
        var serviceType: String {
            switch self {
            case .temperature: return HMServiceTypeTemperatureSensor
            case .humidity: return HMServiceTypeHumiditySensor
            }
        }
        
        var characteristicType: String {
            switch self {
            case .temperature: return HMCharacteristicTypeCurrentTemperature
            case .humidity: return HMCharacteristicTypeCurrentRelativeHumidity
            }
        }
    }
    
    // MARK: - Initialization
    override public init() {
        self.homeManager = HMHomeManager()
        super.init()
        self.homeManager.delegate = self
        
        // Add home delegate if there's a primary home
        if let primaryHome = homeManager.primaryHome {
            primaryHome.delegate = self
            logger.debug("Set delegate for primary home: \(primaryHome.name)")
        }
        
        Task { @MainActor in
            logger.debug("🏁 Initializing HomeKit...")
            await checkAuthorization()
        }
    }
    
    // MARK: - Automation Setup
    func setupAutomation(trigger: AutomationTrigger, action: AutomationAction) async throws {
        guard let home = currentHome else {
            throw HomeKitServiceError.homeNotFound
        }
        
        // 1. Create the trigger
        let eventTrigger = try await createEventTrigger(from: trigger, in: home)
        
        // 2. Create the action set
        let actionSet = try await createActionSet(in: home)
        
        // 3. Add actions to the action set
        try await addActions(action, to: actionSet, for: trigger)
        
        // 4. Add and enable the trigger
        try await addTrigger(eventTrigger, to: home, with: actionSet)
    }
    
    // MARK: - Private Helper Methods
    private func createEventTrigger(from trigger: AutomationTrigger, in home: HMHome) async throws -> HMEventTrigger {
        let characteristic = try await getCharacteristic(for: trigger)
        
        switch trigger {
        case .temperature(let type), .humidity(let type):
            switch type {
            case .threshold(let value, let comparison):
                let predicate = NSPredicate(
                    format: "%K %@ %@",
                    characteristic.characteristicType,
                    comparison == .greaterThan ? ">" : "<",
                    NSNumber(value: value)
                )
                
                let event = HMCharacteristicEvent(
                    characteristic: characteristic,
                    triggerValue: NSNumber(value: value)
                )
                
                return HMEventTrigger(
                    name: "Value Threshold",
                    events: [event],
                    predicate: predicate
                )
                
            case .time(let components):
                let calendarEvent = HMCalendarEvent(fire: components)
                return HMEventTrigger(
                    name: "Time-based",
                    events: [calendarEvent],
                    predicate: nil
                )
            }
        }
    }
    
    private func createActionSet(in home: HMHome) async throws -> HMActionSet {
        try await withCheckedThrowingContinuation { continuation in
            home.addActionSet(withName: "Automation Action") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HMError(.noActionsInActionSet))
                }
            }
        }
    }
    
    private func addActions(_ action: AutomationAction, to actionSet: HMActionSet, for trigger: AutomationTrigger) async throws {
        let characteristic = try await getCharacteristic(for: trigger)
        
        switch action {
        case .alert(let actionType):
            switch actionType {
            case .notification(let message):
                // Create write action
                let writeAction = HMCharacteristicWriteAction(
                    characteristic: characteristic,
                    targetValue: NSNumber(value: 1)
                )
                
                // Add write action first
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    actionSet.addAction(writeAction) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                
                // Create and add notification action
                let notificationAction = try await createNotificationAction(message: message)
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    actionSet.addAction(notificationAction) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                
                // Ensure notifications are registered
                try await registerForNotifications()
                
            case .setValue(let value, _):
                let writeAction = HMCharacteristicWriteAction(
                    characteristic: characteristic,
                    targetValue: NSNumber(value: value)
                )
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    actionSet.addAction(writeAction) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
        case .adjust:
            break
        }
    }
    
    private func addTrigger(_ trigger: HMEventTrigger, to home: HMHome, with actionSet: HMActionSet) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(trigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // Add this helper method for notification registration
    private func registerForNotifications() async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Check current authorization status
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            // Request authorization
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            if !granted {
                throw HomeKitServiceError.authorizationFailed
            }
        case .denied:
            throw HomeKitServiceError.authorizationFailed
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
        
        // Register notification category if needed
        let category = UNNotificationCategory(
            identifier: "HUMIDOR_ALERT",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    // Helper methods to handle action creation and addition
    private func createNotificationAction(message: String) async throws -> HMAction {
        // Create a characteristic write action that will trigger the notification
        let characteristic = try await getCharacteristic(for: .temperature(.threshold(value: 0, comparison: .greaterThan)))
        
        let writeAction = HMCharacteristicWriteAction(
            characteristic: characteristic,
            targetValue: NSNumber(value: 1)
        )
        
        // Create a unique notification key using UUID
        let notificationKey = "notification-\(UUID().uuidString)"
        
        // Store notification details in UserDefaults for later use
        UserDefaults.standard.set([
            "message": message,
            "title": "Humidor Alert",
            "category": "HUMIDOR_ALERT"
        ], forKey: notificationKey)
        
        // Add observer for the characteristic change
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HMCharacteristicValueUpdateNotification"),
            object: characteristic,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Handle notification when characteristic changes
            if let notificationData = UserDefaults.standard.dictionary(forKey: notificationKey),
               let message = notificationData["message"] as? String {
                
                let content = UNMutableNotificationContent()
                content.title = notificationData["title"] as? String ?? "Humidor Alert"
                content.body = message
                content.sound = .default
                content.categoryIdentifier = notificationData["category"] as? String ?? "HUMIDOR_ALERT"
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                
                UNUserNotificationCenter.current().add(request)
                
                // Clean up
                UserDefaults.standard.removeObject(forKey: notificationKey)
            }
        }
        
        return writeAction
    }
    
    private func addActionToSet(_ action: HMAction, to actionSet: HMActionSet) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            actionSet.addAction(action) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // Make checkAuthorization public and async
    @MainActor
    public func checkAuthorization() async {
        let manager = self.homeManager
        self.authorizationStatus = manager.authorizationStatus
        self.isAuthorized = manager.authorizationStatus.contains(.authorized)
        
        logger.debug("Authorization check complete")
        logger.debug("- Authorization status raw value: \(String(describing: manager.authorizationStatus))")
        logger.debug("- Contains authorized: \(manager.authorizationStatus.contains(.authorized))")
        logger.debug("- Is authorized: \(self.isAuthorized)")
        logger.debug("- Homes count: \(manager.homes.count)")
        
        // Wait for home manager to fully initialize if needed
        if manager.homes.isEmpty && self.isAuthorized {
            logger.debug("Waiting for home manager to initialize...")
            // Wait up to 5 seconds for homes to be loaded
            for _ in 0..<10 {
                if !manager.homes.isEmpty {
                    break
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                logger.debug("Still waiting for homes... Current count: \(manager.homes.count)")
            }
        }
        
        // If still no homes exist after waiting, create one
        if self.isAuthorized && manager.homes.isEmpty {
            logger.debug("No homes found, attempting to create one...")
            do {
                let home = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMHome, Error>) in
                    manager.addHome(withName: "My Home") { [weak self] home, error in
                        guard let self = self else { return }
                        if let error = error {
                            self.logger.error("Failed to create home: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        } else if let home = home {
                            self.logger.debug("Successfully created home: \(home.name)")
                            continuation.resume(returning: home)
                        } else {
                            self.logger.error("No home created and no error returned")
                            continuation.resume(throwing: HomeKitServiceError.homeNotFound)
                        }
                    }
                }
                self.currentHome = home
                logger.debug("Set current home to: \(home.name)")
                
                // Set up home delegate
                home.delegate = self
                logger.debug("Set up home delegate")
                
                // Wait briefly for home to be fully set up
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                await refreshAccessories()
            } catch {
                logger.error("Failed to create home: \(error.localizedDescription)")
                if let hmError = error as? HMError {
                    logger.error("HMError code: \(hmError.code.rawValue)")
                }
            }
        } else if let primaryHome = manager.primaryHome {
            logger.debug("Using existing primary home: \(primaryHome.name)")
            self.currentHome = primaryHome
            primaryHome.delegate = self
            await refreshAccessories()
        } else if let firstHome = manager.homes.first {
            logger.debug("Using first available home: \(firstHome.name)")
            self.currentHome = firstHome
            firstHome.delegate = self
            await refreshAccessories()
        }
        
        // Final state logging
        logger.debug("Final state:")
        logger.debug("- Has homes: \(manager.homes.count > 0)")
        logger.debug("- Current home: \(self.currentHome?.name ?? "none")")
        logger.debug("- Primary home: \(manager.primaryHome?.name ?? "none")")
        logger.debug("- Total homes: \(manager.homes.count)")
        
        // Mark as initialized after everything is set up
        self.isInitialized = true
        
        // Notify UI of state change
        objectWillChange.send()
    }
    
    // Add a method to force refresh the state
    @MainActor
    public func refreshState() async {
        self.isInitialized = false
        await checkAuthorization()
    }
    
    @MainActor
    func refreshCharacteristics() async {
        // Refresh temperature sensors
        for sensor in temperatureSensors {
            if let service = sensor.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
                try? await characteristic.readValue()
            }
        }
        
        // Refresh humidity sensors
        for sensor in humiditySensors {
            if let service = sensor.services.first(where: { $0.serviceType == HMServiceTypeHumiditySensor }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }) {
                try? await characteristic.readValue()
            }
        }
    }
}

// MARK: - HMHomeManagerDelegate
extension HomeKitService: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        logger.debug("🏠 HomeManager did update homes")
        logger.debug("Number of homes: \(manager.homes.count)")
        logger.debug("Homes: \(manager.homes.map { $0.name })")
        logger.debug("Primary home: \(manager.primaryHome?.name ?? "none")")
        
        Task { [weak self] in
            guard let self = self else { return }
            await self.checkAuthorization()
        }
    }
    
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        logger.debug("🏠 HomeManager did update primary home")
        logger.debug("New primary home: \(manager.primaryHome?.name ?? "none")")
        
        Task { [weak self] in
            guard let self = self else { return }
            self.currentHome = manager.primaryHome
            await self.refreshAccessories()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        logger.debug("➕ Home added: \(home.name)")
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        logger.debug("➖ Home removed: \(home.name)")
    }
    
    func homeManager(_ manager: HMHomeManager, didReceiveAddAccessoryRequest request: HMAddAccessoryRequest) {
        logger.debug("📱 Received add accessory request")
    }
    
    func homeManager(_ manager: HMHomeManager, didFailWithError error: Error) {
        logger.error("❌ HomeManager failed with error: \(error.localizedDescription)")
        if let hmError = error as? HMError {
            logger.error("HMError code: \(hmError.code.rawValue)")
            logger.error("HMError description: \(hmError.localizedDescription)")
        }
    }
}

// Add Home delegate methods
extension HomeKitService: HMHomeDelegate {
    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        logger.debug("➕ Added accessory to home: \(accessory.name)")
        logger.debug("Accessory type: \(accessory.category.categoryType)")
        logger.debug("Services: \(accessory.services.map { $0.serviceType })")
        
        Task { @MainActor in
            await refreshAccessories()
        }
    }
    
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        logger.debug("➖ Removed accessory from home: \(accessory.name)")
        
        Task { @MainActor in
            await refreshAccessories()
        }
    }
    
    func home(_ home: HMHome, didUpdateNameFor accessory: HMAccessory) {
        logger.debug("✏️ Updated accessory name: \(accessory.name)")
    }
    
    func home(_ home: HMHome, didEncounterError error: Error, for accessory: HMAccessory) {
        logger.error("❌ Error with accessory \(accessory.name): \(error.localizedDescription)")
    }
}

// Add this helper class to HomeKitService
private class NotificationActionHandler: NSObject {
    private let message: String
    private let logger = Logger(subsystem: "com.smokejourney", category: "NotificationHandler")
    
    init(message: String) {
        self.message = message
        super.init()
    }
    
    @objc func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Humidor Alert"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "HUMIDOR_ALERT"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { [logger] error in
            if let error = error {
                logger.error("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                logger.debug("Successfully scheduled humidor alert notification")
            }
        }
    }
}

// Add missing methods
extension HomeKitService {
    @MainActor
    func addAccessory(name: String, type: SensorType) async throws {
        guard isAuthorized else {
            throw HomeKitServiceError.authorizationFailed
        }
        
        guard let home = currentHome else {
            throw HomeKitServiceError.homeNotFound
        }
        
        logger.debug("Adding \(type.rawValue) sensor named: \(name)")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addAndSetupAccessories { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Refresh accessories list after adding new one
        await refreshAccessories()
    }
    
    func refreshAccessories() async {
        guard let home = self.currentHome else { return }
        
        let accessories = home.accessories
        
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.temperatureSensors = accessories.filter { accessory in
                accessory.services.contains { service in
                    service.serviceType == HMServiceTypeTemperatureSensor
                }
            }
            
            self.humiditySensors = accessories.filter { accessory in
                accessory.services.contains { service in
                    service.serviceType == HMServiceTypeHumiditySensor
                }
            }
        }
    }
    
    private func getCharacteristic(for trigger: AutomationTrigger) async throws -> HMCharacteristic {
        guard let home = currentHome else {
            throw HomeKitServiceError.homeNotFound
        }
        
        let serviceType: String
        let characteristicType: String
        
        switch trigger {
        case .temperature:
            serviceType = HMServiceTypeTemperatureSensor
            characteristicType = HMCharacteristicTypeCurrentTemperature
        case .humidity:
            serviceType = HMServiceTypeHumiditySensor
            characteristicType = HMCharacteristicTypeCurrentRelativeHumidity
        }
        
        guard let accessory = home.accessories.first(where: { accessory in
            accessory.services.contains { $0.serviceType == serviceType }
        }),
        let service = accessory.services.first(where: { $0.serviceType == serviceType }),
        let characteristic = service.characteristics.first(where: { $0.characteristicType == characteristicType })
        else {
            throw HomeKitServiceError.characteristicNotFound
        }
        
        return characteristic
    }
    
    @MainActor
    func selectSensor(_ accessory: HMAccessory, type: SensorType) async {
        // Store the selected sensor
        switch type {
        case .temperature:
            if let service = accessory.services.first(where: { $0.serviceType == type.serviceType }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == type.characteristicType }) {
                // Enable notifications for this characteristic
                try? await characteristic.enableNotification(true)
                logger.debug("Enabled notifications for temperature sensor: \(accessory.name)")
            }
            
        case .humidity:
            if let service = accessory.services.first(where: { $0.serviceType == type.serviceType }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == type.characteristicType }) {
                // Enable notifications for this characteristic
                try? await characteristic.enableNotification(true)
                logger.debug("Enabled notifications for humidity sensor: \(accessory.name)")
            }
        }
        
        // Refresh the accessory list
        await refreshAccessories()
    }
    
    func readSensorValue(_ accessory: HMAccessory, type: SensorType) async throws -> Double {
        guard let service = accessory.services.first(where: { $0.serviceType == type.serviceType }),
              let characteristic = service.characteristics.first(where: { $0.characteristicType == type.characteristicType }),
              let value = characteristic.value as? Double else {
            throw HomeKitServiceError.characteristicNotFound
        }
        return value
    }
    
    func startMonitoring(humidor: Humidor) {
        // Set up characteristic notifications
        Task {
            if let tempID = humidor.temperatureSensorID,
               let sensor = temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == tempID }),
               let service = sensor.services.first(where: { $0.serviceType == SensorType.temperature.serviceType }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == SensorType.temperature.characteristicType }) {
                try? await characteristic.enableNotification(true)
                
                // Store reading when value changes
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("HMCharacteristicValueUpdateNotification"),
                    object: characteristic,
                    queue: .main
                ) { [weak self] _ in
                    guard let value = characteristic.value as? Double else { return }
                    Task {
                        await self?.storeReading(value: value, type: .temperature, for: humidor)
                    }
                }
            }
            
            // Similar setup for humidity sensor
            if let humidityID = humidor.humiditySensorID,
               let sensor = humiditySensors.first(where: { $0.uniqueIdentifier.uuidString == humidityID }),
               let service = sensor.services.first(where: { $0.serviceType == SensorType.humidity.serviceType }),
               let characteristic = service.characteristics.first(where: { $0.characteristicType == SensorType.humidity.characteristicType }) {
                try? await characteristic.enableNotification(true)
                
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("HMCharacteristicValueUpdateNotification"),
                    object: characteristic,
                    queue: .main
                ) { [weak self] _ in
                    guard let value = characteristic.value as? Double else { return }
                    Task {
                        await self?.storeReading(value: value, type: .humidity, for: humidor)
                    }
                }
            }
        }
    }
    
    private func storeReading(value: Double, type: SensorType, for humidor: Humidor) async {
        let readingType: SensorReading.ReadingType = type == .temperature ? .temperature : .humidity
        
        let reading = SensorReading(
            value: value,
            type: readingType,
            humidorPersistentID: String(describing: humidor.persistentModelID)
        )
        
        // Store reading in SwiftData
        await MainActor.run {
            if let context = humidor.modelContext {
                context.insert(reading)
                try? context.save()
            }
        }
    }
}
