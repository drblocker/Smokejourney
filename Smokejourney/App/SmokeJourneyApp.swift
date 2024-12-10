import SwiftUI
import SwiftData
import CloudKit

@main
struct SmokeJourneyApp: App {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
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
                EnvironmentSettings.self
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
                .task {
                    // Initialize CloudKit after view appears
                    do {
                        try await cloudKitManager.setupCloudKit()
                    } catch {
                        print("Failed to initialize CloudKit: \(error.localizedDescription)")
                    }
                }
        }
    }
}