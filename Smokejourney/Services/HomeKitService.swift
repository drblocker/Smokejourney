import Foundation
import HomeKit
import os.log
import SwiftUI

@MainActor
final class HomeKitService: NSObject, ObservableObject {
    static let shared = HomeKitService()
    private let logger = Logger(subsystem: "com.smokejourney", category: "HomeKit")
    
    enum SensorType: String, CaseIterable {
        case temperature = "Temperature"
        case humidity = "Humidity"
        
        var characteristicType: String {
            switch self {
            case .temperature:
                return HMCharacteristicTypeCurrentTemperature
            case .humidity:
                return HMCharacteristicTypeCurrentRelativeHumidity
            }
        }
        
        var unit: String {
            switch self {
            case .temperature: return "°F"
            case .humidity: return "%"
            }
        }
        
        var defaultThreshold: Double {
            switch self {
            case .temperature: return 70.0
            case .humidity: return 65.0
            }
        }
    }
    
    enum HomeKitError: LocalizedError {
        case noHome
        case noAccessory
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .noHome:
                return "No HomeKit home configured"
            case .noAccessory:
                return "No compatible accessory found"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var temperatureSensors: [HMAccessory] = []
    @Published private(set) var home: HMHome?
    
    private let homeManager = HMHomeManager()
    
    private override init() {
        super.init()
        homeManager.delegate = self
    }
    
    func requestAuthorization() async throws {
        if homeManager.authorizationStatus.contains(.authorized) {
            isAuthorized = true
            
            // Get or create primary home
            if let primaryHome = homeManager.homes.first {
                home = primaryHome
            } else {
                home = try await createHome()
            }
            
            await refreshAccessories()
        } else {
            throw HMError(.homeAccessNotAuthorized)
        }
    }
    
    private func createHome() async throws -> HMHome {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMHome, Error>) in
            homeManager.addHome(withName: "My Home") { home, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let home = home {
                    continuation.resume(returning: home)
                } else {
                    continuation.resume(throwing: HMError(.genericError))
                }
            }
        }
    }
    
    func addAccessory() async throws {
        guard let home = home else {
            throw HMError(.homeAccessNotAuthorized)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addAndSetupAccessories { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func refreshAccessories() async {
        guard let home = home else { return }
        
        temperatureSensors = home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.characteristics.contains { characteristic in
                    characteristic.characteristicType == HMCharacteristicTypeCurrentTemperature
                }
            }
        }
    }
    
    func setupAutomation(trigger: AutomationTrigger, action: AutomationAction) async throws {
        guard let home = home else { throw HomeKitError.noHome }
        
        // Create the action set
        let actionSet = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: "Action Set") { actionSet, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let actionSet = actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: HomeKitError.unknown)
                }
            }
        }
        
        // Configure the trigger based on type
        let eventTrigger = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMEventTrigger, Error>) in
            do {
                switch trigger {
                case .temperature(let type), .humidity(let type):
                    let characteristic = try getCharacteristic(for: trigger)
                    let trigger = HMEventTrigger(name: "Climate Trigger", events: [], predicate: nil)
                    
                    switch type {
                    case .threshold(let value, let comparison):
                        home.addTrigger(trigger) { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                trigger.addActionSet(actionSet) { error in
                                    if let error = error {
                                        continuation.resume(throwing: error)
                                    } else {
                                        // Set the predicate
                                        let predicate = NSPredicate(format: "%K %@ %@",
                                                                  characteristic.characteristicType,
                                                                  comparison == .greaterThan ? ">" : "<",
                                                                  value as NSNumber)
                                        trigger.updatePredicate(predicate) { error in
                                            if let error = error {
                                                continuation.resume(throwing: error)
                                            } else {
                                                continuation.resume(returning: trigger)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    case .time(let components):
                        // Convert DateComponents to Date
                        guard let fireDate = Calendar.current.date(from: components) else {
                            continuation.resume(throwing: HomeKitError.unknown)
                            return
                        }
                        
                        let trigger = HMTimerTrigger(name: "Time Trigger", 
                                                    fireDate: fireDate,  // Use Date instead of DateComponents
                                                    timeZone: .current,
                                                    recurrence: nil,
                                                    recurrenceCalendar: nil)
                        
                        // Add action set after creation
                        trigger.addActionSet(actionSet) { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                home.addTrigger(trigger) { error in
                                    if let error = error {
                                        continuation.resume(throwing: error)
                                    } else {
                                        continuation.resume(returning: trigger as! HMEventTrigger)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        // Enable the trigger
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            eventTrigger.enable(true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    private func getCharacteristic(for trigger: AutomationTrigger) throws -> HMCharacteristic {
        guard let accessory = temperatureSensors.first else {
            throw HomeKitError.noAccessory
        }
        
        let characteristicType: String
        switch trigger {
        case .temperature:
            characteristicType = HMCharacteristicTypeCurrentTemperature
        case .humidity:
            characteristicType = HMCharacteristicTypeCurrentRelativeHumidity
        }
        
        guard let characteristic = accessory.services.flatMap({ $0.characteristics })
            .first(where: { $0.characteristicType == characteristicType }) else {
            throw HomeKitError.noAccessory
        }
        
        return characteristic
    }
}

extension HomeKitService: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        home = manager.homes.first
        Task {
            await refreshAccessories()
        }
    }
}
