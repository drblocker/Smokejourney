import Foundation
import SwiftData
import os.log
import AuthenticationServices

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "No user found with this email"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Network connection error"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "Authentication")
    
    @Published var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
            if !isAuthenticated {
                // Clear user data when signing out
                UserDefaults.standard.removeObject(forKey: "userIdentifier")
            }
        }
    }
    @Published var currentUser: User?
    
    private init() {
        // Load authentication state from UserDefaults
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        logger.debug("Initialized with auth state: \(self.isAuthenticated)")
    }
    
    func signIn(user: User) {
        self.currentUser = user
        self.isAuthenticated = true
        // Save user identifier - convert to string representation
        let userId = String(describing: user.persistentModelID)
        UserDefaults.standard.set(userId, forKey: "userIdentifier")
        logger.debug("User signed in: \(userId)")
    }
    
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
        logger.debug("User signed out")
    }
    
    func restoreUser(from modelContext: ModelContext) {
        guard isAuthenticated,
              let _ = UserDefaults.standard.string(forKey: "userIdentifier") else {
            return
        }
        
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                self.currentUser = user
                logger.debug("Restored user session: \(String(describing: user.persistentModelID))")
            } else {
                // No user found, clear authentication
                signOut()
                logger.error("No user found in database")
            }
        } catch {
            logger.error("Failed to restore user: \(error.localizedDescription)")
            signOut()
        }
    }
} 
