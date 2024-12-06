import SwiftUI
import SwiftData

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @AppStorage("sensorPushAuthenticated") private var isSensorPushAuthenticated = false
    @State private var showSensorPushAuth = false
    
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
                        // SensorPush Authentication Status
                        HStack {
                            Label("SensorPush", systemImage: "sensor.fill")
                            Spacer()
                            if isSensorPushAuthenticated {
                                Label("Connected", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button(action: { showSensorPushAuth = true }) {
                                    Text("Sign In")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        NavigationLink(destination: SensorManagementView()) {
                            Label("Manage Sensors", systemImage: "sensor.fill")
                        }
                        .disabled(!isSensorPushAuthenticated)
                        
                        NavigationLink(destination: HumidorAlertSettingsView()) {
                            Label("Alert Settings", systemImage: "bell.badge")
                        }
                        .disabled(!isSensorPushAuthenticated)
                    }
                    
                    Section("Statistics") {
                        NavigationLink(destination: StatisticsView()) {
                            Label("View Statistics", systemImage: "chart.bar")
                        }
                    }
                    
                    Section("Account") {
                        if isSensorPushAuthenticated {
                            Button(role: .destructive) {
                                signOutSensorPush()
                            } label: {
                                Label("Sign Out of SensorPush", systemImage: "sensor.fill")
                            }
                        }
                        
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
            .sheet(isPresented: $showSensorPushAuth) {
                NavigationStack {
                    SensorPushAuthView()
                }
            }
        }
    }
    
    private func signOut() async {
        if let user = users.first {
            modelContext.delete(user)
        }
        signOutSensorPush()
        isAuthenticated = false
    }
    
    private func signOutSensorPush() {
        SensorPushService.shared.signOut()
        isSensorPushAuthenticated = false
    }
}

#Preview {
    ProfileView(isAuthenticated: .constant(true))
} 