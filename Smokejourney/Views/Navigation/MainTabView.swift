import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NavigationStack {
                HumidorListView()
            }
            .tabItem {
                Label("Humidors", systemImage: "cabinet")
            }
            
            NavigationStack {
                ClimateView(modelContext: modelContext)
            }
            .tabItem {
                Label("Climate", systemImage: "thermometer")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: User.self, inMemory: true)
} 