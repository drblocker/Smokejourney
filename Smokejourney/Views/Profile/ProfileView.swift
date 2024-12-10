import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var homeKitManager = HomeKitManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingHomeKitSetup = false
    @State private var selectedHumidor: Humidor?
    @State private var showingLogoutAlert = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            if let name = user.name {
                                Text(name)
                                    .font(.headline)
                            }
                            if let email = user.email {
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                            Text("Member since: \(user.memberSince)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        Button("Sign Out", role: .destructive) {
                            showingLogoutAlert = true
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    NavigationLink("Environment Settings") {
                        EnvironmentSettingsView()
                    }
                    
                    NavigationLink("Notifications") {
                        NotificationSettingsView()
                    }
                }
                
                Section("HomeKit Integration") {
                    Toggle("Enable HomeKit", isOn: $homeKitManager.isAuthorized)
                        .onChange(of: homeKitManager.isAuthorized) { isEnabled in
                            if isEnabled {
                                Task {
                                    try? await homeKitManager.requestAuthorization()
                                }
                            }
                        }
                    
                    if homeKitManager.isAuthorized {
                        NavigationLink("HomeKit Settings") {
                            if let humidor = selectedHumidor {
                                HomeKitSetupView(humidor: humidor)
                            }
                        }
                        
                        if let home = homeKitManager.currentHome {
                            Text("Current Home: \(home.name)")
                        }
                    }
                }
                
                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://www.example.com/terms")!)
                    Text("Version \(Bundle.main.appVersionString)")
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                        try? await clearAllData()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? This will remove all local data.")
            }
            .onAppear {
                // Verify authentication state
                if authManager.isAuthenticated && authManager.currentUser == nil {
                    Task {
                        await authManager.signOut()
                    }
                }
            }
        }
    }
    
    private func clearAllData() async throws {
        // Delete all entities
        try await modelContext.delete(model: User.self)
        try await modelContext.delete(model: Humidor.self)
        try await modelContext.delete(model: Cigar.self)
        try await modelContext.delete(model: CigarPurchase.self)
        try await modelContext.delete(model: Review.self)
        try await modelContext.delete(model: SmokingSession.self)
        try await modelContext.delete(model: EnvironmentSettings.self)
        
        // Save changes to ensure CloudKit sync
        try modelContext.save()
        
        // Reset HomeKit state
        homeKitManager.isAuthorized = false
        homeKitManager.availableAccessories = []
        homeKitManager.availableRooms = []
        homeKitManager.currentHome = nil
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: User.self, inMemory: true)
} 