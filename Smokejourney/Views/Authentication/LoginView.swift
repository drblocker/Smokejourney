import SwiftUI
import SwiftData
import AuthenticationServices
import os.log

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isAuthenticated: Bool
    @StateObject private var authManager = AuthenticationManager.shared
    private let logger = Logger(subsystem: "com.smokejourney", category: "Authentication")
    
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
            SignInWithAppleButton(
                onRequest: configureAppleSignIn,
                onCompletion: handleAppleSignIn
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
            
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
    }
    
    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                logger.error("Unable to get Apple ID credentials")
                return
            }
            
            // Create user
            let user = User()
            if let email = appleIDCredential.email {
                user.email = email
            }
            if let fullName = appleIDCredential.fullName {
                user.displayName = [
                    fullName.givenName,
                    fullName.familyName
                ].compactMap { $0 }.joined(separator: " ")
            }
            user.appleUserIdentifier = appleIDCredential.user
            user.updateLastSignIn()
            
            // Save to SwiftData
            modelContext.insert(user)
            
            withAnimation {
                isAuthenticated = true
            }
            
            logger.debug("Successfully signed in with Apple")
            
        case .failure(let error):
            logger.error("Apple sign in failed: \(error.localizedDescription)")
        }
    }
    
    private func checkExistingAuth() async {
        if UserDefaults.standard.bool(forKey: "isAuthenticated") {
            let users = try? modelContext.fetch(FetchDescriptor<User>())
            if let user = users?.first {
                logger.debug("Restoring existing user session")
                authManager.restoreUser(user)
                isAuthenticated = true
            } else {
                logger.error("No user found in database")
                authManager.signOut()
            }
        }
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
        .modelContainer(for: User.self)
} 