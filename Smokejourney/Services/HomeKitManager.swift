import HomeKit
import os.log
import SwiftUI

class HomeKitManager: NSObject, ObservableObject {
    static let shared = HomeKitManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "HomeKit")
    
    @Published var isAuthorized = false
    @Published var availableRooms: [HMRoom] = []
    @Published var availableAccessories: [HMAccessory] = []
    @Published var authorizationStatus: HMHomeManagerAuthorizationStatus = .determined as HMHomeManagerAuthorizationStatus
    
    @Published var currentHome: HMHome?
    
    private var homeManager: HMHomeManager!
    
    @Published var selectedRoom: HMRoom?
    @Published var isPairing = false
    @Published var pairingError: String?
    @Published var automations: [HMAction] = []
    
    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager.delegate = self
        
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    @MainActor
    func checkAuthorizationStatus() async {
        let status = homeManager.authorizationStatus
        authorizationStatus = status
        isAuthorized = (status == .authorized)
        logger.debug("HomeKit authorization status: \(status.rawValue)")
    }
    
    func requestAuthorization() async throws {
        logger.debug("Requesting HomeKit authorization")
        
        let status = homeManager.authorizationStatus
        
        switch status {
        case .authorized:
            logger.debug("HomeKit already authorized")
            await MainActor.run {
                isAuthorized = true
                authorizationStatus = .authorized
            }
            
        case .determined:
            logger.error("HomeKit access not determined")
            throw HomeKitError.authorizationDenied
            
        case .restricted:
            logger.error("HomeKit access restricted")
            throw HomeKitError.authorizationDenied
            
        default:
            logger.error("Unknown HomeKit authorization status: \(status.rawValue)")
            throw HomeKitError.authorizationDenied
        }
        
        try await updateHomes()
    }
    
    private func updateHomes() async throws {
        guard let manager = homeManager else { return }
        
        currentHome = manager.primaryHome ?? manager.homes.first
        
        if let home = currentHome {
            availableRooms = home.rooms
            availableAccessories = home.accessories
            isAuthorized = true
        } else {
            isAuthorized = false
            throw HomeKitError.noHomeFound
        }
    }
    
    func configureSensorAutomation(for humidor: Humidor) async throws {
        guard isAuthorized else {
            throw HomeKitError.notAuthorized
        }
        
        guard let home = currentHome else {
            throw HomeKitError.noHomeFound
        }
        
        logger.debug("Setting up automations for humidor: \(humidor.effectiveName)")
        
        await cleanupExistingAutomations(for: humidor)
        
        if let tempSensorId = humidor.homeKitTemperatureSensorID,
           let tempService = findService(withId: tempSensorId) {
            try await setupTemperatureAutomations(
                service: tempService,
                targetTemp: humidor.targetTemperature ?? 70.0,
                tolerance: 2.0,
                home: home,
                humidor: humidor
            )
        }
        
        if let humSensorId = humidor.homeKitHumiditySensorID,
           let humService = findService(withId: humSensorId) {
            try await setupHumidityAutomations(
                service: humService,
                targetHumidity: humidor.targetHumidity ?? 65.0,
                tolerance: 3.0,
                home: home,
                humidor: humidor
            )
        }
        
        logger.debug("Automations setup completed")
    }
    
    private func setupTemperatureAutomations(
        service: HMService,
        targetTemp: Double,
        tolerance: Double,
        home: HMHome,
        humidor: Humidor
    ) async throws {
        guard let tempCharacteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
        }) else {
            throw HomeKitError.setupFailed("Temperature characteristic not found")
        }
        
        try await tempCharacteristic.readValue()
        guard let currentTemp = tempCharacteristic.value as? Double else {
            throw HomeKitError.setupFailed("Could not read temperature value")
        }
        
        // Create action sets
        let highTempActionSet = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: "High Temperature Actions") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HomeKitError.setupFailed("Failed to create action set"))
                }
            }
        }
        
        let lowTempActionSet = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: "Low Temperature Actions") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HomeKitError.setupFailed("Failed to create action set"))
                }
            }
        }
        
        // Create and add actions
        let highTempAction = HMCharacteristicWriteAction(
            characteristic: tempCharacteristic,
            targetValue: NSNumber(value: 1)
        )
        
        let lowTempAction = HMCharacteristicWriteAction(
            characteristic: tempCharacteristic,
            targetValue: NSNumber(value: 0)
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            highTempActionSet.addAction(highTempAction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowTempActionSet.addAction(lowTempAction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Create and add trigger
        let trigger = HMEventTrigger(
            name: "High Temperature Alert",
            events: [HMCharacteristicEvent(
                characteristic: tempCharacteristic,
                triggerValue: targetTemp + tolerance as NSNumber
            )],
            predicate: nil
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(trigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            trigger.addActionSet(highTempActionSet) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            trigger.enable(true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Create triggers
        let highTempTrigger = HMEventTrigger(
            name: "High Temperature Alert",
            events: [HMCharacteristicEvent(
                characteristic: tempCharacteristic,
                triggerValue: targetTemp + tolerance as NSNumber
            )],
            predicate: nil
        )
        
        let lowTempTrigger = HMEventTrigger(
            name: "Low Temperature Alert",
            events: [HMCharacteristicEvent(
                characteristic: tempCharacteristic,
                triggerValue: targetTemp - tolerance as NSNumber
            )],
            predicate: nil
        )
        
        // Add and configure triggers
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(highTempTrigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            highTempTrigger.addActionSet(highTempActionSet) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(lowTempTrigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowTempTrigger.addActionSet(lowTempActionSet) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowTempTrigger.enable(true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Check thresholds and send alerts if needed
        if currentTemp > targetTemp + tolerance {
            handleEnvironmentalAlert(type: .temperatureHigh(currentTemp), for: humidor)
        } else if currentTemp < targetTemp - tolerance {
            handleEnvironmentalAlert(type: .temperatureLow(currentTemp), for: humidor)
        }
    }
    
    private func setupHumidityAutomations(
        service: HMService,
        targetHumidity: Double,
        tolerance: Double,
        home: HMHome,
        humidor: Humidor
    ) async throws {
        guard let humCharacteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity
        }) else {
            throw HomeKitError.setupFailed("Humidity characteristic not found")
        }
        
        // Read current humidity
        try await humCharacteristic.readValue()
        guard let currentHumidity = humCharacteristic.value as? Double else {
            throw HomeKitError.setupFailed("Could not read humidity value")
        }
        
        // Create action sets
        let highHumActionSet = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: "High Humidity Actions") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HomeKitError.setupFailed("Failed to create action set"))
                }
            }
        }
        
        let lowHumActionSet = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: "Low Humidity Actions") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HomeKitError.setupFailed("Failed to create action set"))
                }
            }
        }
        
        // Create actions
        let highHumAction = HMCharacteristicWriteAction(
            characteristic: humCharacteristic,
            targetValue: NSNumber(value: 1)
        )
        let lowHumAction = HMCharacteristicWriteAction(
            characteristic: humCharacteristic,
            targetValue: NSNumber(value: 0)
        )
        
        // Add actions to action sets
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            highHumActionSet.addAction(highHumAction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowHumActionSet.addAction(lowHumAction) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Create and configure triggers
        let highHumTrigger = HMEventTrigger(
            name: "High Humidity Alert",
            events: [HMCharacteristicEvent(
                characteristic: humCharacteristic,
                triggerValue: targetHumidity + tolerance as NSNumber
            )],
            predicate: nil
        )
        
        let lowHumTrigger = HMEventTrigger(
            name: "Low Humidity Alert",
            events: [HMCharacteristicEvent(
                characteristic: humCharacteristic,
                triggerValue: targetHumidity - tolerance as NSNumber
            )],
            predicate: nil
        )
        
        // Add triggers to home
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(highHumTrigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(lowHumTrigger) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Associate action sets with triggers
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            highHumTrigger.addActionSet(highHumActionSet) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowHumTrigger.addActionSet(lowHumActionSet) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Enable triggers
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            highHumTrigger.enable(true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lowHumTrigger.enable(true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        logger.debug("Humidity automations configured")
        
        // Check current humidity against thresholds
        if currentHumidity > targetHumidity + tolerance {
            handleEnvironmentalAlert(
                type: .humidityHigh(currentHumidity),
                for: humidor
            )
        } else if currentHumidity < targetHumidity - tolerance {
            handleEnvironmentalAlert(
                type: .humidityLow(currentHumidity),
                for: humidor
            )
        }
    }
    
    private func cleanupExistingAutomations(for humidor: Humidor) async {
        guard let home = currentHome else { return }
        
        for trigger in home.triggers where trigger.name.contains(humidor.effectiveName) {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    home.removeTrigger(trigger) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
            } catch {
                logger.error("Failed to remove trigger: \(error.localizedDescription)")
            }
        }
        
        logger.debug("Cleaned up existing automations")
    }
    
    func selectRoom(_ room: HMRoom, for humidor: Humidor) async throws {
        guard isAuthorized else {
            throw HomeKitError.notAuthorized
        }
        
        guard let home = currentHome else {
            throw HomeKitError.noHomeFound
        }
        
        // Verify room exists in current home
        guard home.rooms.contains(room) else {
            throw HomeKitError.roomNotFound
        }
        
        await MainActor.run {
            selectedRoom = room
            humidor.homeKitRoomName = room.name
        }
        
        logger.debug("Selected room: \(room.name)")
    }
    
    func createRoom(name: String) async throws -> HMRoom {
        guard isAuthorized else {
            throw HomeKitError.notAuthorized
        }
        
        guard let home = currentHome else {
            throw HomeKitError.noHomeFound
        }
        
        do {
            let room = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMRoom, Error>) in
                home.addRoom(withName: name) { room, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let room = room {
                        continuation.resume(returning: room)
                    } else {
                        continuation.resume(throwing: HomeKitError.setupFailed("Failed to create room"))
                    }
                }
            }
            
            await MainActor.run {
                availableRooms = home.rooms.sorted { $0.name < $1.name }
            }
            logger.debug("Created new room: \(name)")
            return room
        } catch {
            logger.error("Failed to create room: \(error.localizedDescription)")
            throw HomeKitError.setupFailed("Failed to create room: \(error.localizedDescription)")
        }
    }
    
    func getRoomAccessories(_ room: HMRoom) -> [HMAccessory] {
        return room.accessories.sorted { $0.name < $1.name }
    }
    
    func startSensorPairing() async throws {
        guard let home = currentHome else {
            throw HomeKitError.noHomeFound
        }
        
        await MainActor.run {
            isPairing = true
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addAndSetupAccessories { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func stopSensorPairing() async {
        guard let home = currentHome else { return }
        
        try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addAndSetupAccessories { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        await MainActor.run {
            isPairing = false
        }
    }
    
    func getTemperature(for humidor: Humidor) async throws -> Double? {
        guard let sensorId = humidor.homeKitTemperatureSensorID,
              let service = findService(withId: sensorId),
              let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) else {
            return nil
        }
        
        try await characteristic.readValue()
        return characteristic.value as? Double
    }
    
    func getHumidity(for humidor: Humidor) async throws -> Double? {
        guard let sensorId = humidor.homeKitHumiditySensorID,
              let service = findService(withId: sensorId),
              let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }) else {
            return nil
        }
        
        try await characteristic.readValue()
        return characteristic.value as? Double
    }
    
    private func findService(withId id: String) -> HMService? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        for accessory in availableAccessories {
            if let service = accessory.services.first(where: { $0.uniqueIdentifier == uuid }) {
                return service
            }
        }
        
        return nil
    }
    
    private func handleEnvironmentalAlert(type: EnvironmentNotificationManager.NotificationType, for humidor: Humidor) {
        Task {
            await EnvironmentNotificationManager.shared.scheduleNotification(type: type, for: humidor)
        }
    }
    
    func updateTemperature(_ temperature: Double, for humidor: Humidor) async throws {
        guard let sensorId = humidor.homeKitTemperatureSensorID,
              let service = findService(withId: sensorId),
              let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) else {
            throw HomeKitError.characteristicNotFound
        }
        
        // Check temperature thresholds using the environment settings
        if temperature > humidor.effectiveMaxTemperature {
            handleEnvironmentalAlert(type: .temperatureHigh(temperature), for: humidor)
        } else if temperature < humidor.effectiveMinTemperature {
            handleEnvironmentalAlert(type: .temperatureLow(temperature), for: humidor)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            characteristic.writeValue(temperature) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func updateHumidity(_ humidity: Double, for humidor: Humidor) async throws {
        guard let sensorId = humidor.homeKitHumiditySensorID,
              let service = findService(withId: sensorId),
              let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }) else {
            throw HomeKitError.characteristicNotFound
        }
        
        // Check humidity thresholds using the environment settings
        if humidity > humidor.effectiveMaxHumidity {
            handleEnvironmentalAlert(type: .humidityHigh(humidity), for: humidor)
        } else if humidity < humidor.effectiveMinHumidity {
            handleEnvironmentalAlert(type: .humidityLow(humidity), for: humidor)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            characteristic.writeValue(humidity) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

// MARK: - HMHomeManagerDelegate
extension HomeKitManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        logger.debug("HomeKit homes updated")
        Task {
            try? await updateHomes()
        }
    }
    
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        logger.debug("HomeKit primary home updated")
        Task {
            try? await updateHomes()
        }
    }
} 
