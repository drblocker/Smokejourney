import SwiftUI
import SwiftData
import HomeKit
import OSLog
import CloudKit

// Custom string conversion for HomeKit authorization status
extension HMHomeManagerAuthorizationStatus {
    var statusDescription: String {
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
            User.self,
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
            ContentView()
        }
        .environmentObject(homeKitManager)
        .environmentObject(sensorPushManager)
        .environmentObject(authManager)
        .modelContainer(sharedModelContainer)
    }
} 