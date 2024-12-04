import SwiftUI
import SwiftData

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    var body: some View {
        NavigationStack {
            List {
                if let user = users.first {
                    Section {
                        ProfileHeader(user: user)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    
                    Section("Environmental Monitoring") {
                        NavigationLink(destination: SensorManagementView()) {
                            Label("Manage Sensors", systemImage: "sensor.fill")
                        }
                        
                        NavigationLink(destination: HumidorAlertSettingsView()) {
                            Label("Alert Settings", systemImage: "bell.badge")
                        }
                    }
                    
                    Section("Statistics") {
                        NavigationLink(destination: StatisticsView()) {
                            Label("View Statistics", systemImage: "chart.bar")
                        }
                    }
                    
                    Section("Account") {
                        Button(role: .destructive) {
                            Task {
                                await signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func signOut() async {
        if let user = users.first {
            modelContext.delete(user)
        }
        await SensorPushService.shared.signOut()
        isAuthenticated = false
    }
}

#Preview {
    ProfileView(isAuthenticated: .constant(true))
} 