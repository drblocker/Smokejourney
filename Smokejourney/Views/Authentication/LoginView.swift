import SwiftUI
import SwiftData
import AuthenticationServices
import os.log

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo/Branding
            Image(systemName: "flame.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("SmokeJourney")
                .font(.largeTitle)
                .bold()
            
            Text("Track your cigar journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Sign in with Apple Button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    do {
                        try await authManager.handleSignInWithApple(result)
                        isAuthenticated = true
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }
            }
            .frame(height: 44)
            .padding()
            
            // Privacy Note
            Text("Your data is stored securely and synced across your devices using iCloud")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .task {
            await checkExistingAuth()
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func checkExistingAuth() async {
        if UserDefaults.standard.bool(forKey: "isAuthenticated") {
            let users = try? modelContext.fetch(FetchDescriptor<User>())
            if let user = users?.first {
                authManager.restoreUser(from: modelContext)
                await MainActor.run {
                    isAuthenticated = true
                }
            } else {
                await authManager.signOut()
            }
        }
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
        .modelContainer(for: [
            User.self,
            Humidor.self,
            Cigar.self,
            CigarPurchase.self,
            Review.self,
            SmokingSession.self,
            EnvironmentSettings.self
        ], inMemory: true)
} 