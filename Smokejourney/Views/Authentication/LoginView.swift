import SwiftUI
import SwiftData
import AuthenticationServices

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager: AuthenticationManager
    
    init(isAuthenticated: Binding<Bool>, modelContext: ModelContext) {
        _isAuthenticated = isAuthenticated
        _authManager = StateObject(wrappedValue: AuthenticationManager(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 10) {
                Image(systemName: "smoke")
                    .font(.system(size: 60))
                Text("SmokeJourney")
                    .font(.title)
                    .bold()
            }
            
            Spacer()
            
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    do {
                        try await authManager.handleSignInWithApple(result)
                        isAuthenticated = true
                    } catch {
                        // Error handling is managed by AuthManager
                    }
                }
            }
            .frame(height: 50)
            .padding(.horizontal)
            
            // Privacy and Terms links
            HStack {
                Link("Privacy Policy", destination: URL(string: "https://smokejourney.app/privacy")!)
                Text("•")
                Link("Terms of Service", destination: URL(string: "https://smokejourney.app/terms")!)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .padding()
        .alert("Authentication Error", isPresented: .constant(authManager.error != nil)) {
            Button("OK") {
                authManager.error = nil
            }
        } message: {
            if let error = authManager.error {
                Text(error.localizedDescription)
            }
        }
    }
} 