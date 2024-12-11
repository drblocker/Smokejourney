import SwiftUI
import SwiftData
import CloudKit
import HomeKit
import OSLog

// Move extension outside of the app struct
extension HMHomeManagerAuthorizationStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        if self.contains(.authorized) {
            return "authorized"
        } else if self.contains(.determined) {
            return "determined"
        } else if self.contains(.restricted) {
            return "restricted"
        } else {
            return "unknown"
        }
    }
}

@main
struct SmokeJourneyApp: App {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @StateObject private var homeKitManager = HomeKitService.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "HomeKit")
    let container: ModelContainer
    
    init() {
        // Create a temporary container to avoid capture issues
        let tempContainer: ModelContainer
        
        do {
            // Define schema
            let schema = Schema([
                User.self,
                Cigar.self,
                CigarPurchase.self,
                Review.self,
                SmokingSession.self,
                Humidor.self,
                EnvironmentSettings.self,
                Sensor.self,
                SensorReading.self
            ])
            
            // Configure SwiftData with CloudKit
            let modelConfiguration = ModelConfiguration(
                "Default",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.jason.smokejourney"),
                cloudKitDatabase: .private(
                    "iCloud.com.jason.smokejourney"
                )
            )
            
            // Create container
            tempContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
        } catch {
            fatalError("Failed to configure SwiftData: \(error.localizedDescription)")
        }
        
        // Assign to instance property
        self.container = tempContainer
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(cloudKitManager)
                .environmentObject(homeKitManager)
                .environmentObject(SensorPushService.shared)
                .task {
                    do {
                        // First initialize CloudKit
                        try await cloudKitManager.setupCloudKit()
                        
                        // Then initialize HomeKit with retries
                        try await verifyHomeKitAuthorization()
                    } catch {
                        print("Service initialization error: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    private enum AuthorizationError: LocalizedError {
        case timeout
        case authorizationFailed
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .timeout:
                return "HomeKit authorization timed out"
            case .authorizationFailed:
                return "Failed to authorize HomeKit access"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    private func verifyHomeKitAuthorization() async throws {
        let maxRetries = 3
        var currentTry = 0
        
        logger.debug("Starting HomeKit authorization verification")
        logger.debug("Current authorization status: \(String(describing: homeKitManager.authorizationStatus))")
        logger.debug("Is authorized: \(homeKitManager.isAuthorized)")
        
        while currentTry < maxRetries {
            do {
                logger.debug("Attempt \(currentTry + 1) of \(maxRetries)")
                
                try await withTimeout(seconds: 5) {
                    logger.debug("Checking authorization with timeout")
                    await homeKitManager.checkAuthorization()
                    
                    // Add delay to allow HomeKit to fully initialize
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    logger.debug("Authorization check completed")
                    logger.debug("Status contains authorized: \(self.homeKitManager.authorizationStatus.contains(.authorized))")
                }
                
                // Verify authorization was successful
                if homeKitManager.authorizationStatus.contains(.authorized) {
                    logger.notice("🟢 HomeKit successfully authorized")
                    if let home = homeKitManager.currentHome {
                        logger.debug("Primary home: \(home.name)")
                    } else {
                        logger.debug("No home available yet")
                    }
                    return
                }
                
                currentTry += 1
                if currentTry < maxRetries {
                    logger.warning("⚠️ Authorization attempt \(currentTry) failed")
                    logger.debug("Status: \(String(describing: homeKitManager.authorizationStatus))")
                    logger.debug("Waiting before retry...")
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            } catch is TimeoutError {
                currentTry += 1
                logger.error("🔴 Authorization timeout on attempt \(currentTry)")
                logger.debug("Last known status: \(String(describing: homeKitManager.authorizationStatus))")
            } catch {
                logger.error("🔴 Unexpected error: \(error.localizedDescription)")
                throw AuthorizationError.unknown(error)
            }
        }
        
        logger.error("🔴 Failed to authorize after \(maxRetries) attempts")
        logger.error("Final status: \(String(describing: homeKitManager.authorizationStatus))")
        throw AuthorizationError.authorizationFailed
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Only handle notification permissions in AppDelegate
        Task {
            do {
                let notificationCenter = UNUserNotificationCenter.current()
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                print("Notification permission \(granted ? "granted" : "denied")")
            } catch {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        return true
    }
}

// Timeout handling
private struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}