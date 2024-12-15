import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthenticationManager.shared
    @AppStorage("isOnboarding") private var isOnboarding = true
    
    var body: some View {
        Group {
            if isOnboarding {
                OnboardingView()
            } else if authManager.isAuthenticated {
                MainTabView()
                    .environment(\.modelContext, modelContext)
            } else {
                SignInView()
            }
        }
        .environmentObject(authManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
} 