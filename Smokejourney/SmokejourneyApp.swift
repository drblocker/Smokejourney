import SwiftUI
import SwiftData
import HomeKit

@main
struct SmokejourneyApp: App {
    let modelContainer: ModelContainer
    let backgroundTaskHandler: BackgroundTaskHandler
    
    init() {
        do {
            // Configure CloudKit schema and container
            let schema = Schema([
                Humidor.self,
                Cigar.self,
                ClimateSensor.self,
                SensorReading.self,
                Sensor.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier("group.com.jason.smokejourney"),
                cloudKitDatabase: .automatic,
                migrations: [
                    .automaticallyMigrateStores: true,
                    .inferMappingModelAutomatically: true,
                    .enablePersistentHistoryTracking: true,
                    .enableRemoteChangeNotifications: true
                ]
            )
            
            // Initialize container with configuration
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: modelConfiguration
            )
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        backgroundTaskHandler = BackgroundTaskHandler(modelContext: modelContainer.mainContext)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(HomeKitService.shared)
                .environmentObject(SensorPushService.shared)
        }
    }
} 
