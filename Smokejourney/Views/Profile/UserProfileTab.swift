import SwiftUI
import SwiftData

struct UserProfileTab: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    var body: some View {
        NavigationStack {
            List {
                if let user = users.first {
                    Section {
                        ProfileHeaderView(user: user)
                    }
                    
                    Section("Account") {
                        Button(role: .destructive, action: signOut) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func signOut() {
        // Clear user data
        if let user = users.first {
            modelContext.delete(user)
        }
        
        // Sign out from services
        SensorPushService.shared.signOut()
        
        // Update authentication state
        isAuthenticated = false
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 4) {
                Text(user.effectiveName)
                    .font(.title2)
                    .bold()
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
} 