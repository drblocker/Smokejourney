import Foundation
import AuthenticationServices
import SwiftData
import UIKit

enum AuthError: LocalizedError {
    case signInFailed(String)
    case noCredential
    case userCancelled
    case profilePictureError
    case credentialRevoked
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .noCredential:
            return "Unable to get user credentials"
        case .userCancelled:
            return "Sign in was cancelled"
        case .profilePictureError:
            return "Unable to load profile picture"
        case .credentialRevoked:
            return "Apple ID credentials have been revoked"
        }
    }
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private let modelContext: ModelContext
    private var credentialStateSubscription: Task<Void, Never>?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
        Task {
            await checkAuthenticationState()
            await startCredentialStateMonitoring()
        }
    }
    
    deinit {
        credentialStateSubscription?.cancel()
    }
    
    private func startCredentialStateMonitoring() async {
        guard let userIdentifier = currentUser?.appleUserIdentifier else { return }
        
        credentialStateSubscription?.cancel()
        credentialStateSubscription = Task {
            while !Task.isCancelled {
                do {
                    let state = try await ASAuthorizationAppleIDProvider()
                        .credentialState(forUserID: userIdentifier)
                    
                    handleCredentialState(state)
                    try await Task.sleep(nanoseconds: 60 * NSEC_PER_SEC) // Check every minute
                } catch {
                    print("Error checking credential state: \(error)")
                }
            }
        }
    }
    
    private func handleCredentialState(_ state: ASAuthorizationAppleIDProvider.CredentialState) {
        switch state {
        case .revoked:
            error = .credentialRevoked
            Task { await signOut() }
        case .notFound:
            Task { await signOut() }
        case .authorized:
            break // All good
        default:
            break
        }
    }
    
    private func checkAuthenticationState() async {
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                currentUser = user
                isAuthenticated = true
                await startCredentialStateMonitoring()
            }
        } catch {
            self.error = .signInFailed(error.localizedDescription)
        }
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.noCredential
            }
            
            // Create or update user
            let user = try await createOrUpdateUser(from: credential)
            currentUser = user
            isAuthenticated = true
            
            // Start monitoring credential state
            await startCredentialStateMonitoring()
            
        case .failure(let error as ASAuthorizationError):
            switch error.code {
            case .canceled:
                throw AuthError.userCancelled
            default:
                throw AuthError.signInFailed(error.localizedDescription)
            }
        case .failure(let error):
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    private func createOrUpdateUser(from credential: ASAuthorizationAppleIDCredential) async throws -> User {
        // Check for existing user with the Apple ID
        let appleID = credential.user
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { user in
                if let userID = user.appleUserIdentifier {
                    return userID == appleID
                } else {
                    return false
                }
            },
            sortBy: [SortDescriptor(\User.createdAt, order: .reverse)]
        )
        
        let existingUsers = try await modelContext.fetch(descriptor)
        
        if let existingUser = existingUsers.first {
            // Update existing user with any new information
            await MainActor.run {
                if let email = credential.email {
                    existingUser.email = email
                }
                if let fullName = credential.fullName {
                    let displayName = [
                        fullName.givenName,
                        fullName.familyName
                    ].compactMap { $0 }.joined(separator: " ")
                    existingUser.displayName = displayName.isEmpty ? nil : displayName
                }
                existingUser.lastSignInDate = Date()
            }
            return existingUser
        } else {
            // Create new user
            let displayName = credential.fullName.map { fullName in
                [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
            
            let user = User(
                email: credential.email ?? "",
                displayName: displayName,
                appleUserIdentifier: credential.user
            )
            
            await MainActor.run {
                modelContext.insert(user)
            }
            return user
        }
    }
    
    func signOut() async {
        // Cancel any ongoing monitoring
        credentialStateSubscription?.cancel()
        
        // Clear SensorPush authentication
        await SensorPushService.shared.signOut()
        
        // Clear all user data
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            for user in users {
                modelContext.delete(user)
            }
            
            // Save changes immediately
            try modelContext.save()
            
            // Reset authentication state
            currentUser = nil
            isAuthenticated = false
            
            // Clear any cached data
            UserDefaults.standard.removeObject(forKey: "sensorPushAuthenticated")
            UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        } catch {
            print("Error clearing user data: \(error)")
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        
        do {
            // First, ensure we're starting with a clean state
            await signOut()
            
            // Attempt to authenticate with SensorPush
            let token = try await SensorPushService.shared.authenticate(email: email, password: password)
            
            // If successful, create new user
            let user = User(email: email)
            modelContext.insert(user)
            try modelContext.save()
            
            // Update state
            currentUser = user
            isAuthenticated = true
            
            // Start monitoring credentials
            await startCredentialStateMonitoring()
        } catch {
            throw error
        }
    }
} 
