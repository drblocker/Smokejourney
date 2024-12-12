import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HumidorListView()
                .tabItem {
                    Label("Humidors", systemImage: "cabinet")
                }
                .tag(0)
            
            ClimateView()
                .tabItem {
                    Label("Climate", systemImage: "thermometer")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(AuthenticationManager.shared)
} 