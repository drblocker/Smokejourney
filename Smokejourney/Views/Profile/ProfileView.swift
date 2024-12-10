import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingLogoutAlert = false
    @State private var showingSettings = false
    
    var body: some View {
        List {
            // User Info Section
            Section {
                if let user = users.first {
                    ProfileHeader(user: user)
                } else {
                    Text("No user information available")
                        .foregroundColor(.secondary)
                }
            }
            
            // Settings Section
            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                
                NavigationLink {
                    DataManagementView()
                } label: {
                    Label("Data Management", systemImage: "externaldrive")
                }
                
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
            
            // Sign Out Section
            Section {
                Button(role: .destructive) {
                    showingLogoutAlert = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() async {
        do {
            // Clear user data
            for user in users {
                modelContext.delete(user)
            }
            try modelContext.save()
            
            // Sign out through auth manager
            try await authManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(for: User.self, inMemory: true)
    }
} 