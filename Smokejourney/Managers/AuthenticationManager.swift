import Foundation
import OSLog
import AuthenticationServices
import SwiftData

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "Auth")
    private let keychain = KeychainManager.shared
    private let userIdKey = "com.smokejourney.userId"
    
    private init() {}
    
    func handleSignInWithApple(_ credentials: ASAuthorizationAppleIDCredential, context: ModelContext) async throws {
        // Process the user data
        let userId = credentials.user
        let email = credentials.email
        let fullName = credentials.fullName
        
        // Create or update user
        let user = try await createOrUpdateUser(
            id: userId,
            email: email,
            firstName: fullName?.givenName,
            lastName: fullName?.familyName,
            context: context
        )
        
        // Update state
        currentUser = user
        isAuthenticated = true
        
        // Save credentials
        do {
            try keychain.set(userId, forKey: userIdKey)
            logger.info("Successfully signed in user: \(userId)")
        } catch {
            logger.error("Failed to save credentials: \(error.localizedDescription)")
            throw AuthError.keychain(error)
        }
    }
    
    func restoreUser(from context: ModelContext) async throws {
        guard !isAuthenticated else { return }
        
        // Try to get stored user ID
        guard let userId = keychain.string(forKey: userIdKey) else {
            logger.debug("No stored user ID found")
            return
        }
        
        // Fetch user from SwiftData
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == userId
            }
        )
        
        let users = try context.fetch(descriptor)
        if let user = users.first {
            currentUser = user
            isAuthenticated = true
            logger.info("Successfully restored user session")
        } else {
            throw AuthError.userNotFound
        }
    }
    
    func signOut() {
        keychain.remove(forKey: userIdKey)
        currentUser = nil
        isAuthenticated = false
        logger.info("User signed out")
    }
    
    private func createOrUpdateUser(
        id: String,
        email: String?,
        firstName: String?,
        lastName: String?,
        context: ModelContext
    ) async throws -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == id
            }
        )
        
        let existingUsers = try context.fetch(descriptor)
        if let existingUser = existingUsers.first {
            // Update existing user
            if let email = email { existingUser.email = email }
            if let firstName = firstName { existingUser.firstName = firstName }
            if let lastName = lastName { existingUser.lastName = lastName }
            return existingUser
        } else {
            // Create new user
            let newUser = User(
                id: id,
                email: email ?? "",
                firstName: firstName ?? "",
                lastName: lastName ?? ""
            )
            context.insert(newUser)
            return newUser
        }
    }
    
    enum AuthError: LocalizedError {
        case userNotFound
        case invalidCredentials
        case keychain(Error)
        
        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "User not found. Please sign in again."
            case .invalidCredentials:
                return "Invalid credentials. Please try again."
            case .keychain(let error):
                return "Keychain error: \(error.localizedDescription)"
            }
        }
    }
} 