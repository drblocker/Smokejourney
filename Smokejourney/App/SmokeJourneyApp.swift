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
struct SmokejourneyApp: App {
    @StateObject private var homeKitManager = HomeKitService()
    @StateObject private var sensorPushManager = SensorPushService()
    @StateObject private var authManager = AuthenticationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Humidor.self,
            Cigar.self,
            SensorReading.self,
            EnvironmentSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                HumidorView()
                    .tabItem {
                        Label("Humidors", systemImage: "cabinet")
                    }
                
                ClimateView()
                    .tabItem {
                        Label("Climate", systemImage: "thermometer")
                    }
                
                StatisticsView()
                    .tabItem {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
            }
            .environmentObject(homeKitManager)
            .environmentObject(sensorPushManager)
            .environmentObject(authManager)
            .modelContainer(sharedModelContainer)
        }
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