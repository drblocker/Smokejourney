@main
struct SmokejourneyApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
        .modelContainer(for: [User.self, Humidor.self, EnvironmentSettings.self])
    }
} 