import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
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