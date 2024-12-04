import CloudKit
import SwiftUI
import SwiftData
import os.log

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case iCloudAccountNotFound
    case networkError
    case quotaExceeded
    case serverError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to enable sync"
        case .iCloudAccountNotFound:
            return "No iCloud account found. Please sign in to iCloud in Settings"
        case .networkError:
            return "Network connection error. Please check your internet connection"
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up some space"
        case .serverError(let error):
            return "Server error: \(error.localizedDescription)"
        }
    }
}

final class CloudKitManager {
    static let shared = CloudKitManager()
    private let containerIdentifier = "iCloud.com.jason.smokejourney"
    private var container: CKContainer?
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "CloudKit")
    
    private init() {
        container = CKContainer(identifier: containerIdentifier)
    }
    
    func verifyiCloudAccount() async throws {
        guard let container = container else {
            throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
        }
        
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available:
                logger.debug("iCloud account available")
                return
            case .noAccount:
                logger.error("No iCloud account found")
                throw CloudKitError.iCloudAccountNotFound
            case .restricted:
                logger.error("iCloud account restricted")
                throw CloudKitError.notAuthenticated
            case .couldNotDetermine:
                logger.error("Could not determine iCloud account status")
                throw CloudKitError.networkError
            @unknown default:
                logger.error("Unknown iCloud account status")
                throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -2))
            }
        } catch {
            logger.error("iCloud verification failed: \(error.localizedDescription)")
            throw CloudKitError.serverError(error)
        }
    }
    
    func setupModelConfiguration() -> ModelConfiguration {
        let schema = Schema([
            Cigar.self,
            User.self,
            Humidor.self,
            SmokingSession.self,
            Review.self
        ])
        
        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private(containerIdentifier)
        )
    }
    
    func handleCloudKitError(_ error: Error) -> CloudKitError {
        guard let ckError = error as? CKError else {
            return .serverError(error)
        }
        
        switch ckError.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .quotaExceeded:
            return .quotaExceeded
        case .networkFailure, .networkUnavailable:
            return .networkError
        default:
            return .serverError(error)
        }
    }
} 