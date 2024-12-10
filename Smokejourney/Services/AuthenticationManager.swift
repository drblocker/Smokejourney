import Foundation
import AuthenticationServices
import SwiftData
import OSLog
import CloudKit

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "Authentication")
    private var modelContext: ModelContext?
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                logger.debug("Sign in with Apple successful for user ID: \(userId)")
                
                // Check CloudKit status first
                try await CloudKitManager.shared.verifyCloudKitAccess()
                
                // Try to find existing user
                if let existingUser = try await fetchUser(withId: userId) {
                    logger.debug("Found existing user: \(existingUser.effectiveName)")
                    
                    // Update user info if provided
                    if let email = appleIDCredential.email {
                        existingUser.email = email
                    }
                    if let fullName = appleIDCredential.fullName {
                        let name = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        if !name.isEmpty {
                            existingUser.name = name
                        }
                    }
                    
                    existingUser.updateLastSignIn()
                    try modelContext?.save()
                    
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isAuthenticated = true
                    }
                } else {
                    logger.debug("Creating new user")
                    let newUser = User(
                        id: userId,
                        email: appleIDCredential.email,
                        name: [appleIDCredential.fullName?.givenName, 
                              appleIDCredential.fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                    )
                    
                    modelContext?.insert(newUser)
                    try modelContext?.save()
                    
                    logger.debug("New user created: \(newUser.effectiveName)")
                    
                    await MainActor.run {
                        self.currentUser = newUser
                        self.isAuthenticated = true
                    }
                }
                
                // Save user ID to keychain
                try await KeychainManager.shared.saveUserIdentifier(userId)
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                logger.debug("Authentication completed successfully")
                
            } else {
                logger.error("Invalid credential type")
                throw AuthError.invalidCredential
            }
            
        case .failure(let error):
            logger.error("Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func restoreUser(from context: ModelContext) {
        let logger = Logger(subsystem: "com.smokejourney", category: "Auth")
        logger.debug("Attempting to restore user from model context")
        
        Task {
            do {
                // Verify CloudKit data
                logger.debug("Verifying CloudKit data")
                try await verifyCloudKitData(context: context)
                
                // Check if we have a stored user ID
                if let userId = try await KeychainManager.shared.getUserIdentifier() {
                    logger.debug("Found user ID in keychain: \(userId)")
                    
                    // Fetch user from context
                    logger.debug("Fetching user with ID: \(userId)")
                    let descriptor = FetchDescriptor<User>(
                        predicate: #Predicate<User> { user in
                            user.id == userId
                        }
                    )
                    
                    let users = try context.fetch(descriptor)
                    if let existingUser = users.first {
                        logger.debug("Found existing user:")
                        self.currentUser = existingUser
                        self.isAuthenticated = true
                        logger.debug("Successfully restored user:")
                    } else {
                        logger.debug("No user found with ID: \(userId)")
                        clearState()
                    }
                } else {
                    logger.debug("No user ID found in keychain")
                    clearState()
                }
            } catch {
                logger.error("Failed to restore user: \(error.localizedDescription)")
                clearState()
            }
        }
    }
    
    private func fetchUser(withId id: String) async throws -> User? {
        guard let context = modelContext else {
            logger.error("No model context available")
            throw AuthError.noContext
        }
        
        logger.debug("Fetching user with ID: \(id)")
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                user.id == id
            }
        )
        
        let existingUsers = try context.fetch(descriptor)
        if let user = existingUsers.first {
            logger.debug("Found existing user: \(user.effectiveName)")
        } else {
            logger.debug("No user found with ID: \(id)")
        }
        return existingUsers.first
    }
    
    func signOut() async {
        logger.debug("Signing out user")
        
        // Clear keychain
        try? await KeychainManager.shared.clearUserIdentifier()
        
        // Clear authentication state
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
        
        logger.debug("User signed out successfully")
    }
    
    private func verifyCloudKitData(context: ModelContext) async throws {
        let logger = Logger(subsystem: "com.smokejourney", category: "Auth")
        logger.debug("Checking iCloud account status")
        
        guard let accountStatus = try? await CKContainer.default().accountStatus() else {
            logger.error("Failed to get iCloud account status")
            throw AuthError.cloudKitError
        }
        
        guard accountStatus == .available else {
            logger.error("iCloud account not available: \(accountStatus.rawValue)")
            throw AuthError.cloudKitError
        }
        
        logger.debug("iCloud account available")
        
        // Verify container access
        let container = CKContainer(identifier: "iCloud.com.jason.smokejourney")
        let database = container.privateCloudDatabase
        
        do {
            let zones = try await database.allRecordZones()
            logger.debug("Successfully fetched \(zones.count) record zones")
            logger.debug("CloudKit container accessible, checking data")
        } catch {
            logger.error("Failed to access CloudKit container: \(error.localizedDescription)")
            throw AuthError.cloudKitError
        }
    }
    
    private func clearState() {
        Task {
            // Clear keychain
            try? await KeychainManager.shared.clearUserIdentifier()
            
            // Clear authentication state
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            
            logger.debug("Authentication state cleared")
        }
    }
}

enum AuthError: Error {
    case invalidCredential
    case userNotFound
    case saveFailed
    case noContext
    case cloudKitError
}
