import HomeKit
import os.log
import UserNotifications

@MainActor
class HomeKitService: NSObject, ObservableObject, HMHomeManagerDelegate {
    static let shared = HomeKitService()
    private let homeManager = HMHomeManager()
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "HomeKit")
    
    @Published var isAuthorized = false
    @Published var currentHome: HMHome?
    @Published var error: Error?
    @Published var temperatureSensors: [HMAccessory] = []
    @Published var humiditySensors: [HMAccessory] = []
    
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 3
    private var recoveryTimer: Timer?
    private var pendingOperations: [(Date, () async throws -> Void)] = []
    
    // Update the public property to handle the correct type
    var authorizationStatus: UInt {
        homeManager.authorizationStatus.rawValue
    }
    
    enum SensorType {
        case temperature
        case humidity
        
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
    
    private override init() {
        super.init()
        homeManager.delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let status = self.homeManager.authorizationStatus
        
        // Log the raw status for debugging
        logger.debug("HomeKit authorization status: \(status.rawValue)")
        
        // Check iCloud status first
        if FileManager.default.ubiquityIdentityToken == nil {
            logger.error("iCloud not available - HomeKit requires iCloud")
            isAuthorized = false
            return
        }
        
        // Handle all possible authorization states
        switch status.rawValue {
        case 1: // Authorized
            if self.homeManager.homes.isEmpty {
                logger.notice("HomeKit authorized but no homes available")
                isAuthorized = false
            } else {
                logger.debug("HomeKit authorized with \(self.homeManager.homes.count) homes")
                isAuthorized = true
                currentHome = self.homeManager.primaryHome ?? self.homeManager.homes.first
                updateSensorLists()
            }
        
        case 2: // Restricted
            logger.error("HomeKit access restricted")
            isAuthorized = false
        
        case 3: // Determined
            logger.debug("HomeKit authorization determined")
            isAuthorized = false
        
        case 5: // Appears to be a temporary authorization state
            logger.debug("HomeKit in temporary authorization state - waiting for full authorization")
            isAuthorized = false
            // Schedule a recheck after a short delay
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
                checkAuthorization()
            }
        
        default:
            logger.error("Unknown HomeKit authorization status: \(status.rawValue)")
            isAuthorized = false
        }
    }
    
    // Add a method to handle sensor authorization failures
    func handleSensorAuthFailure() {
        logger.error("Sensor authorization failed - attempting to reauthorize")
        // Reset authorization state
        isAuthorized = false
        // Clear any cached data
        temperatureSensors = []
        humiditySensors = []
        // Trigger a recheck of authorization
        checkAuthorization()
    }
    
    // Update the verification method
    func verifyHomeKitSetup() -> Bool {
        // Check if user is signed into iCloud (required for HomeKit)
        if FileManager.default.ubiquityIdentityToken == nil {
            logger.error("User not signed into iCloud")
            return false
        }
        
        // Check authorization status
        if homeManager.authorizationStatus != .authorized {
            logger.error("HomeKit not authorized")
            return false
        }
        
        // Check if we have homes available
        if homeManager.homes.isEmpty {
            logger.notice("No HomeKit homes available")
            return false
        }
        
        return true
    }
    
    func setupAccessory(name: String, sensorType: SensorType) async throws {
        guard let home = currentHome else {
            throw HomeKitError.noHomeSelected
        }
        
        // Create the accessory
        let accessoryName = "\(name) (\(sensorType == .temperature ? "Temperature" : "Humidity"))"
        
        // In a real app, you'd need to handle the actual accessory setup
        // This is just a placeholder since we can't create virtual accessories
        logger.debug("Would create accessory: \(accessoryName)")
        
        // For testing, we can simulate the accessory being added
        // In production, you'd use home.addAndSetupAccessories()
        logger.info("Successfully simulated adding \(accessoryName) to HomeKit")
    }
    
    func updateSensorValue(_ value: Double, for type: SensorType, accessory: HMAccessory) async throws {
        guard let characteristic = accessory.services.first(where: { $0.serviceType == type.serviceType })?
            .characteristics.first(where: { $0.characteristicType == type.characteristicType }) else {
            throw HomeKitError.characteristicNotFound
        }
        
        try await characteristic.writeValue(value)
    }
    
    func setupAutomation(trigger: AutomationTrigger, action: AutomationAction) async throws {
        guard let home = currentHome else {
            throw HomeKitError.noHomeSelected
        }
        
        // Create the action set
        var actionSetRef: HMActionSet?
        let actionSetGroup = DispatchGroup()
        
        actionSetGroup.enter()
        home.addActionSet(withName: action.name) { actionSet, error in
            if let error = error {
                self.logger.error("Failed to create action set: \(error.localizedDescription)")
            }
            actionSetRef = actionSet
            actionSetGroup.leave()
        }
        _ = await actionSetGroup.wait(timeout: .now() + 5)
        
        guard let actionSet = actionSetRef else {
            throw HomeKitError.operationTimeout
        }
        
        // Add actions to the action set
        try await addAction(action, to: actionSet)
        
        // Create the trigger
        let hmTrigger = try await createHMTrigger(from: trigger, in: home)
        
        // Add trigger to home
        let triggerGroup = DispatchGroup()
        triggerGroup.enter()
        home.addTrigger(hmTrigger) { error in
            if let error = error {
                self.logger.error("Failed to add trigger: \(error.localizedDescription)")
            }
            triggerGroup.leave()
        }
        _ = await triggerGroup.wait(timeout: .now() + 5)
    }
    
    private func createHMTrigger(from trigger: AutomationTrigger, in home: HMHome) async throws -> HMEventTrigger {
        switch trigger {
        case .temperature(let type), .humidity(let type):
            switch type {
            case .threshold(let value, let comparison):
                let characteristic = try await getCharacteristic(for: trigger, in: home)
                // Create characteristic event
                let event = HMCharacteristicEvent(
                    characteristic: characteristic,
                    triggerValue: value as NSNumber
                )
                
                return HMEventTrigger(
                    name: trigger.name,
                    events: [event],
                    end: [],
                    recurrences: nil,
                    predicate: nil
                )
                
            case .time(let components):
                // Create calendar event
                let event = HMCalendarEvent(
                    fire: components
                )
                
                return HMEventTrigger(
                    name: trigger.name,
                    events: [event],
                    end: [],
                    recurrences: nil,
                    predicate: nil
                )
            }
        }
    }
    
    private func addAction(_ action: AutomationAction, to actionSet: HMActionSet) async throws {
        let actionGroup = DispatchGroup()
        
        switch action {
        case .alert(let type):
            switch type {
            case .notification(let message):
                // Create user notification
                let content = UNMutableNotificationContent()
                content.title = "HomeKit Alert"
                content.body = message
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
                
                try await UNUserNotificationCenter.current().add(request)
                
            case .setValue(let value, let characteristic):
                actionGroup.enter()
                let writeAction = HMCharacteristicWriteAction(
                    characteristic: characteristic,
                    targetValue: value as NSNumber
                )
                actionSet.addAction(writeAction) { error in
                    if let error = error {
                        self.logger.error("Failed to add write action: \(error.localizedDescription)")
                    }
                    actionGroup.leave()
                }
                _ = await actionGroup.wait(timeout: .now() + 5)
            }
            
        case .adjust(let type):
            try await addAction(.alert(type), to: actionSet)
        }
    }
    
    private func getCharacteristic(for trigger: AutomationTrigger, in home: HMHome) async throws -> HMCharacteristic {
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
            throw HomeKitError.characteristicNotFound
        }
        
        return characteristic
    }
    
    // MARK: - HMHomeManagerDelegate
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        currentHome = manager.primaryHome ?? manager.homes.first
        isAuthorized = manager.homes.count > 0
        
        // Update sensor lists
        updateSensorLists()
    }
    
    private func updateSensorLists() {
        guard let home = currentHome else { return }
        
        temperatureSensors = home.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeTemperatureSensor }
        }
        
        humiditySensors = home.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeHumiditySensor }
        }
    }
}

// MARK: - Error Types
enum HomeKitError: LocalizedError {
    case noHomeSelected
    case accessoryCreationFailed
    case authorizationDenied
    case connectionLost
    case recoveryFailed
    case operationTimeout
    case syncFailed
    case characteristicNotFound
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .noHomeSelected:
            return "No HomeKit home selected"
        case .accessoryCreationFailed:
            return "Failed to create HomeKit accessory"
        case .authorizationDenied:
            return "HomeKit access denied"
        case .connectionLost:
            return "HomeKit connection lost"
        case .recoveryFailed:
            return "Failed to recover HomeKit connection"
        case .operationTimeout:
            return "Operation timed out"
        case .syncFailed:
            return "Failed to sync with HomeKit"
        case .characteristicNotFound:
            return "Characteristic not found"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}

// MARK: - Automation Types
enum AutomationTrigger {
    enum TriggerType {
        case threshold(value: Double, comparison: NSComparisonPredicate.Operator)
        case time(DateComponents)
    }
    
    case temperature(TriggerType)
    case humidity(TriggerType)
    
    var name: String {
        switch self {
        case .temperature: return "Temperature Trigger"
        case .humidity: return "Humidity Trigger"
        }
    }
}

enum AutomationAction {
    enum ActionType {
        case notification(String)
        case setValue(Double, HMCharacteristic)
    }
    
    case alert(ActionType)
    case adjust(ActionType)
    
    var name: String {
        switch self {
        case .alert: return "Alert Action"
        case .adjust: return "Adjustment Action"
        }
    }
} 
