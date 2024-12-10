import SwiftUI
import SwiftData
import AuthenticationServices
import os.log

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    private let logger = Logger(subsystem: "com.smokejourney", category: "Authentication")
    
    private init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>, context: ModelContext) async throws {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                logger.debug("Successfully received Apple ID credential")
                try await signInWithAppleID(credential: appleIDCredential, context: context)
            }
        case .failure(let error):
            logger.error("Sign in with Apple failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func signInWithAppleID(credential: ASAuthorizationAppleIDCredential, context: ModelContext) async throws {
        let userId = credential.user
        let email = credential.email
        let name = credential.fullName?.givenName
        
        let user = User(id: userId, email: email, name: name)
        context.insert(user)
        try context.save()
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
        }
        
        logger.debug("User successfully signed in and saved")
    }
    
    func restoreUser(from context: ModelContext) async throws {
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        
        await MainActor.run {
            if let user = users.first {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    func signOut() async throws {
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
    }
}

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}

enum AuthError: LocalizedError {
    case noModelContext
    case signInFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noModelContext:
            return "No model context available"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        }
    }
} 