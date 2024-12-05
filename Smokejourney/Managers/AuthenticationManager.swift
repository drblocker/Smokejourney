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
    
    @Published var isAuthenticated: Bool
    @Published var currentUser: User?
    
    private init() {
        // Initialize with stored value
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        logger.debug("Initial auth state: \(self.isAuthenticated)")
    }
    
    func processSignIn(with credential: ASAuthorizationAppleIDCredential) async -> User {
        logger.debug("Processing Apple Sign In")
        
        let user = User()
        user.appleUserIdentifier = credential.user
        
        if let email = credential.email {
            user.email = email
        }
        
        if let fullName = credential.fullName {
            user.displayName = [
                fullName.givenName,
                fullName.familyName
            ].compactMap { $0 }.joined(separator: " ")
        }
        
        user.updateLastSignIn()
        currentUser = user
        
        // Update authentication state
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(credential.user, forKey: "userIdentifier")
        
        logger.debug("Apple Sign In successful for user: \(user.effectiveName)")
        return user
    }
    
    func signOut() {
        logger.debug("User signed out")
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userIdentifier")
    }
    
    func restoreUser(_ user: User) {
        currentUser = user
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        if let identifier = user.appleUserIdentifier {
            UserDefaults.standard.set(identifier, forKey: "userIdentifier")
        }
    }
} 
