import Foundation
import SwiftData

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
            return "No account found with this email"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Network error. Please try again"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    private init() {}
    
    func signIn(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Basic validation
        guard email.contains("@") else {
            throw AuthError.invalidCredentials
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // Create a new user (in a real app, this would verify against a backend)
        let displayName = email.components(separatedBy: "@").first
        let user = User(email: email, displayName: displayName)
        user.updateLastSignIn()
        return user
    }
    
    func signUp(email: String, password: String, displayName: String?) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Basic validation
        guard email.contains("@") else {
            throw AuthError.invalidCredentials
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // Create a new user
        let user = User(
            email: email,
            displayName: displayName ?? email.components(separatedBy: "@").first
        )
        user.updateLastSignIn()
        return user
    }
    
    func signOut() {
        // In a real app, this would clear tokens, etc.
    }
} 
