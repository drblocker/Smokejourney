import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .task {
            do {
                try await authManager.restoreUser(from: modelContext)
            } catch {
                print("Failed to restore user: \(error)")
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HumidorListView()
            }
            .tabItem {
                Label("Humidors", systemImage: "cabinet")
            }
            
            NavigationStack {
                EnvironmentalMonitoringView(humidor: Humidor())
            }
            .tabItem {
                Label("Environment", systemImage: "thermometer")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager.shared)
    }
} 