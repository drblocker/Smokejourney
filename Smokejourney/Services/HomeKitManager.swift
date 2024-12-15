import HomeKit
import os.log
import SwiftUI

@MainActor
final class HomeKitManager: NSObject, ObservableObject {
    static let shared = HomeKitManager()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var temperatureSensors: [HMAccessory] = []
    
    private let homeManager = HMHomeManager()
    private var home: HMHome?
    
    private override init() {
        super.init()
        homeManager.delegate = self
    }
    
    enum HomeKitError: LocalizedError {
        case notAuthorized
        case noHome
        case noAccessory
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "HomeKit access not authorized"
            case .noHome:
                return "No home configured in HomeKit"
            case .noAccessory:
                return "Accessory not found"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
    
    func requestAuthorization() async throws {
        guard homeManager.authorizationStatus == .determined else {
            throw HomeKitError.notAuthorized
        }
        
        isAuthorized = true
        
        // Get or create primary home
        if let primaryHome = homeManager.homes.first {
            home = primaryHome
        } else {
            home = try await withCheckedThrowingContinuation { continuation in
                homeManager.addHome(withName: "My Home") { home, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let home = home {
                        continuation.resume(returning: home)
                    } else {
                        continuation.resume(throwing: HomeKitError.unknown)
                    }
                }
            }
        }
        
        await refreshAccessories()
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
}

extension HomeKitManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        home = manager.homes.first
        Task {
            await refreshAccessories()
        }
    }
} 
