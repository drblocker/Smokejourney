import SwiftUI
import SwiftData
import AuthenticationServices
import os.log

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "Auth")
    private let keychain = KeychainManager.shared
    
    private init() {}
    
    func signIn() async {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = SignInDelegate(continuation: continuation)
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                
                // Hold reference to delegate
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
            
            try await handleSignInResult(result)
            
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>, context: ModelContext) async throws {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                try await handleCredential(appleIDCredential, context: context)
            }
        case .failure(let error):
            logger.error("Sign in with Apple failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func handleCredential(_ credential: ASAuthorizationAppleIDCredential, context: ModelContext) async throws {
        let userId = credential.user
        
        // Save user ID to keychain
        try await keychain.saveUserIdentifier(userId)
        
        // Check if user exists
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == userId
            }
        )
        
        let existingUsers = try context.fetch(descriptor)
        
        if let existingUser = existingUsers.first {
            // Update existing user
            if let email = credential.email {
                existingUser.email = email
            }
            if let name = credential.fullName?.givenName {
                existingUser.name = name
            }
            currentUser = existingUser
        } else {
            // Create new user
            let newUser = User(
                id: userId,
                email: credential.email,
                name: credential.fullName?.givenName
            )
            context.insert(newUser)
            currentUser = newUser
        }
        
        try context.save()
        isAuthenticated = true
        logger.debug("User authenticated: \(userId)")
    }
    
    func signOut() async throws {
        // Clear keychain
        try await keychain.clearUserIdentifier()
        
        await MainActor.run {
            currentUser = nil
            isAuthenticated = false
        }
        
        logger.debug("User signed out")
    }
    
    func restoreUser(from context: ModelContext) async throws {
        guard let userId = try await keychain.getUserIdentifier() else {
            logger.debug("No stored user ID found")
            return
        }
        
        logger.debug("Attempting to restore user: \(userId)")
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == userId
            }
        )
        
        let users = try context.fetch(descriptor)
        if let user = users.first {
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            logger.debug("User restored: \(userId)")
        } else {
            logger.debug("No user found with ID: \(userId)")
            try await keychain.clearUserIdentifier()
        }
    }
}

// MARK: - Sign In Delegate
private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
} 