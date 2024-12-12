import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                AppTabView()
            } else {
                SignInView()
            }
        }
        .environmentObject(authManager)
    }
}

private struct AppTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HumidorListView()
            }
            .tabItem {
                Label("Humidors", systemImage: "cabinet")
            }
            .tag(0)
            
            NavigationStack {
                ClimateView()
            }
            .tabItem {
                Label("Climate", systemImage: "thermometer")
            }
            .tag(1)
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
} 