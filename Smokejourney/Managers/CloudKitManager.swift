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
    
    func verifyCloudKitAccess() async throws {
        logger.debug("Checking iCloud account status")
        guard let container = container else {
            throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
        }
        
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
        case .temporarilyUnavailable:
            logger.error("iCloud account temporarily unavailable")
            throw CloudKitError.networkError
        @unknown default:
            logger.error("Unknown iCloud account status")
            throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
        }
    }
    
    func setupModelConfiguration() async -> ModelConfiguration {
        logger.debug("Setting up CloudKit model configuration")
        let schema = Schema([
            Cigar.self,
            User.self,
            Humidor.self,
            SmokingSession.self,
            Review.self,
            CigarPurchase.self,
            EnvironmentSettings.self
        ])
        
        do {
            try await verifyCloudKitAccess()
            logger.debug("iCloud account verified, setting up CloudKit sync")
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .private(containerIdentifier)
            )
        } catch {
            logger.error("Failed to setup CloudKit, falling back to local storage: \(error.localizedDescription)")
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
        }
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
    
    func verifyAndRestoreData() async throws {
        logger.debug("Verifying CloudKit data")
        
        // First verify access
        try await verifyCloudKitAccess()
        
        // Check if we have a container
        guard let container = container else {
            throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
        }
        
        // Fetch private database
        let privateDB = container.privateCloudDatabase
        
        // Log status
        logger.debug("CloudKit container accessible, checking data")
        
        // Trigger a sync using async/await
        return try await withCheckedThrowingContinuation { continuation in
            privateDB.fetchAllRecordZones { zones, error in
                if let error = error {
                    self.logger.error("Failed to fetch record zones: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    self.logger.debug("Successfully fetched \(zones?.count ?? 0) record zones")
                    continuation.resume()
                }
            }
        }
        
        logger.debug("CloudKit data verification complete")
    }
} 