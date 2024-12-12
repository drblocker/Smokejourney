import SwiftUI
import SwiftData

struct ProfileView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showSignOut = false
    
    var body: some View {
        NavigationStack {
            List {
                if authManager.isAuthenticated {
                    // User Info Section
                    Section {
                        if let user = authManager.currentUser {
                            UserInfoRow(user: user)
                        }
                    }
                    
                    // Settings Section
                    Section {
                        NavigationLink("Sensors") {
                            SensorManagementView()
                        }
                        
                        NavigationLink("Environment Settings") {
                            EnvironmentSettingsView()
                        }
                        
                        NavigationLink("Notifications") {
                            NotificationSettingsView()
                        }
                    }
                    
                    // Sign Out Section
                    Section {
                        Button(role: .destructive) {
                            showSignOut = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } else {
                    // Sign In Section
                    Section {
                        SignInView()
                    }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Are you sure you want to sign out?",
                isPresented: $showSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

// Helper Views
struct UserInfoRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.displayName)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SignInView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Button {
            Task {
                await authManager.signIn()
            }
        } label: {
            Label("Sign in with Apple", systemImage: "apple.logo")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(for: User.self, inMemory: true)
    }
} 