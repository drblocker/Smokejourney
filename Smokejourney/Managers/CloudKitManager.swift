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

@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let containerIdentifier = "iCloud.com.jason.smokejourney"
    private var container: CKContainer?
    private let logger = Logger(subsystem: "com.smokejourney", category: "CloudKit")
    private var schedulerRegistration: NSObjectProtocol?
    
    // Add debug flag
    private let isDebugEnabled = false // Set to false to disable debug logging
    
    // Add container lock
    private let containerLock = NSLock()
    private var activeContainer: CKContainer?
    
    @Published var iCloudAvailable = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .unknown
    @Published var debugInfo: [DebugEntry] = []
    
    enum SyncStatus: String {
        case unknown = "Unknown"
        case syncing = "Syncing"
        case success = "Success"
        case error = "Error"
    }
    
    struct DebugEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: DebugLevel
        let message: String
        let error: Error?
        
        enum DebugLevel: String {
            case info = "ℹ️"
            case warning = "⚠️"
            case error = "❌"
            case success = "✅"
        }
    }
    
    private init() {
        setupContainer()
    }
    
    private func setupContainer() {
        containerLock.lock()
        defer { containerLock.unlock() }
        
        // Ensure only one active container
        if activeContainer == nil {
            activeContainer = CKContainer(identifier: containerIdentifier)
            container = activeContainer
        }
    }
    
    func tearDown() {
        containerLock.lock()
        defer { containerLock.unlock() }
        
        if let registration = schedulerRegistration {
            NotificationCenter.default.removeObserver(registration)
            schedulerRegistration = nil
        }
        
        activeContainer = nil
        container = nil
    }
    
    // Add container access method
    func getContainer() -> CKContainer? {
        containerLock.lock()
        defer { containerLock.unlock() }
        return activeContainer
    }
    
    private func registerForSchedulerActivities() {
        // Remove any existing registration
        if let registration = schedulerRegistration {
            NotificationCenter.default.removeObserver(registration)
        }
        
        // Register for CloudKit scheduler activities
        schedulerRegistration = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CKSchedulerActivityRegistration"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let activityID = notification.userInfo?["activityID"] as? String {
                self.logDebug("Received scheduler activity: \(activityID)", level: .info)
                
                // Handle different activity types
                if activityID.contains("export") {
                    self.handleExportActivity()
                } else if activityID.contains("import") {
                    self.handleImportActivity()
                }
            }
        }
    }
    
    private func handleExportActivity() {
        syncStatus = .syncing
        
        Task {
            do {
                guard let container = container else { return }
                let database = container.privateCloudDatabase
                
                // Get all pending changes
                let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
                let changes = try await database.recordZoneChanges(
                    inZoneWith: zone.zoneID,
                    since: nil
                )
                
                let modificationCount = changes.modificationResultsByID.count
                let deletionCount = changes.deletions.count
                
                logDebug("Export completed: \(modificationCount) modifications, \(deletionCount) deletions", level: .success)
                syncStatus = .success
                lastSyncTime = Date()
                
            } catch {
                logDebug("Export failed", level: .error, error: error)
                syncStatus = .error
            }
        }
    }
    
    private func handleImportActivity() {
        syncStatus = .syncing
        
        Task {
            do {
                guard let container = container else { return }
                let database = container.privateCloudDatabase
                
                // Fetch any changes from the server
                let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
                let changes = try await database.recordZoneChanges(
                    inZoneWith: zone.zoneID,
                    since: nil
                )
                
                let modificationCount = changes.modificationResultsByID.count
                let deletionCount = changes.deletions.count
                
                logDebug("Import completed: \(modificationCount) modifications, \(deletionCount) deletions", level: .success)
                syncStatus = .success
                lastSyncTime = Date()
                
            } catch {
                logDebug("Import failed", level: .error, error: error)
                syncStatus = .error
            }
        }
    }
    
    func setupCloudKit() async throws {
        try await setupCloudKitInternal()
    }
    
    private func setupCloudKitInternal() async throws {
        do {
            // Check iCloud account status first
            guard let container = container else {
                throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
            }
            
            let accountStatus = try await container.accountStatus()
            guard accountStatus == .available else {
                logDebug("iCloud account not available: \(accountStatus.description)", level: .error)
                throw CloudKitError.iCloudAccountNotFound
            }
            
            // Verify container access
            let database = container.privateCloudDatabase
            let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
            
            // Create zone if needed
            do {
                try await database.modifyRecordZones(saving: [zone], deleting: [])
                logDebug("Created/verified CloudKit zone", level: .success)
            } catch let error as CKError where error.code == .serverRecordChanged {
                logDebug("Zone already exists", level: .info)
            }
            
            // Validate account info
            let recordID = CKRecord.ID(recordName: "AccountValidation", zoneID: zone.zoneID)
            do {
                _ = try await database.record(for: recordID)
                logDebug("Account validation record exists", level: .success)
            } catch let error as CKError where error.code == .unknownItem {
                // Create validation record
                let record = CKRecord(recordType: "AccountValidation", recordID: recordID)
                record["lastValidation"] = Date() as CKRecordValue
                try await database.save(record)
                logDebug("Created account validation record", level: .success)
            }
            
            // Setup schema
            try await setupCloudKitSchema()
            
            // Mark as available
            await MainActor.run {
                self.iCloudAvailable = true
                self.syncStatus = .success
            }
            
        } catch let error as CKError {
            handleCloudKitError(error)
        } catch {
            logDebug("CloudKit setup failed", level: .error, error: error)
        }
    }
    
    private func setupCloudKitSchema() async throws {
        guard let container = container else { return }
        
        do {
            let database = container.privateCloudDatabase
            let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
            
            // First try to fetch the zone
            do {
                let zones = try await database.allRecordZones()
                if !zones.contains(where: { $0.zoneID.zoneName == zone.zoneID.zoneName }) {
                    try await database.modifyRecordZones(saving: [zone], deleting: [])
                    logDebug("Created new CloudKit zone", level: .success)
                } else {
                    logDebug("Using existing CloudKit zone", level: .info)
                }
            } catch {
                try await database.modifyRecordZones(saving: [zone], deleting: [])
                logDebug("Created CloudKit zone after fetch failure", level: .success)
            }
            
            // Register record types
            let recordTypes = ["User", "Humidor", "Cigar", "CigarPurchase", "Review", "SmokingSession", "EnvironmentSettings"]
            
            for recordType in recordTypes {
                do {
                    // Create a dummy record to establish the record type
                    let recordID = CKRecord.ID(recordName: "\(recordType)_Schema", zoneID: zone.zoneID)
                    let record = CKRecord(recordType: recordType, recordID: recordID)
                    record["schemaVersion"] = "1.0" as CKRecordValue
                    
                    try await database.save(record)
                    logDebug("Created/verified record type: \(recordType)", level: .success)
                } catch let error as CKError where error.code == .serverRecordChanged {
                    logDebug("Record type already exists: \(recordType)", level: .info)
                }
            }
            
            logDebug("CloudKit schema setup complete", level: .success)
            
        } catch {
            logDebug("Failed to setup CloudKit schema", level: .error, error: error)
            throw error
        }
    }
    
    func handleRecordDeletion(recordType: String, recordID: String) async throws {
        guard let container = container else {
            throw CloudKitError.serverError(NSError(domain: "CloudKitManager", code: -1))
        }
        
        let database = container.privateCloudDatabase
        let zone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
        let ckRecordID = CKRecord.ID(recordName: recordID, zoneID: zone.zoneID)
        
        do {
            try await database.deleteRecord(withID: ckRecordID)
            logDebug("Successfully deleted \(recordType) record from CloudKit", level: .success)
        } catch let error as CKError {
            switch error.code {
            case .unknownItem:
                logDebug("Record already deleted from CloudKit", level: .info)
            case .zoneNotFound:
                logDebug("Zone not found while deleting record", level: .error, error: error)
                throw error
            default:
                logDebug("Failed to delete record from CloudKit", level: .error, error: error)
                throw error
            }
        }
    }
    
    private func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .notAuthenticated:
            logDebug("User not authenticated with iCloud", level: .error)
            syncStatus = .error
            iCloudAvailable = false
            
        case .networkFailure, .networkUnavailable:
            logDebug("Network connection error", level: .error)
            syncStatus = .error
            
        case .quotaExceeded:
            logDebug("iCloud quota exceeded", level: .error)
            syncStatus = .error
            
        case .serverRecordChanged:
            logDebug("Server record changed", level: .warning)
            // Handle record conflict
            
        case .zoneNotFound:
            logDebug("CloudKit zone not found", level: .error)
            syncStatus = .error
            
        default:
            logDebug("CloudKit error: \(error.localizedDescription)", level: .error)
            syncStatus = .error
        }
    }
    
    internal func logDebug(_ message: String, level: DebugEntry.DebugLevel, error: Error? = nil) {
        // Only log if debug is enabled
        guard isDebugEnabled else { return }
        
        let entry = DebugEntry(timestamp: Date(), level: level, message: message, error: error)
        debugInfo.insert(entry, at: 0)
        
        switch level {
        case .info:
            logger.info("[\(level.rawValue)] \(message)")
        case .warning:
            logger.warning("[\(level.rawValue)] \(message)")
        case .error:
            if let error = error {
                logger.error("[\(level.rawValue)] \(message): \(error.localizedDescription)")
            } else {
                logger.error("[\(level.rawValue)] \(message)")
            }
        case .success:
            logger.debug("[\(level.rawValue)] \(message)")
        }
    }
}

// MARK: - Helper Extensions
extension CKAccountStatus {
    var description: String {
        switch self {
        case .available: return "Available"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Could Not Determine"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        @unknown default: return "Unknown"
        }
    }
}

// Add this extension to ModelContext to handle CloudKit deletions
extension ModelContext {
    func deleteWithCloudKit<T: PersistentModel>(_ object: T) async throws {
        // Get the ID before deletion
        guard let persistentModelID = object.persistentModelID.storeIdentifier else {
            // If no ID, just delete locally
            await MainActor.run {
                delete(object)
                try? save()
            }
            return
        }
        
        // Store any necessary information before deletion
        let recordType = String(describing: T.self)
        
        // Delete locally first
        await MainActor.run {
            delete(object)
            try? save()
        }
        
        do {
            // Then delete from CloudKit
            try await CloudKitManager.shared.handleRecordDeletion(
                recordType: recordType,
                recordID: persistentModelID
            )
            
            // Fetch fresh data instead of resetting context
            try await refreshData()
            
        } catch {
            // If CloudKit deletion fails, log error but don't revert local deletion
            await MainActor.run {
                CloudKitManager.shared.logDebug(
                    "Error deleting record from CloudKit: \(error.localizedDescription)",
                    level: .error,
                    error: error
                )
            }
        }
    }
    
    private func refreshData() async throws {
        // Fetch fresh data for all model types
        let userDescriptor = FetchDescriptor<User>()
        let humidorDescriptor = FetchDescriptor<Humidor>()
        let cigarDescriptor = FetchDescriptor<Cigar>()
        let purchaseDescriptor = FetchDescriptor<CigarPurchase>()
        let reviewDescriptor = FetchDescriptor<Review>()
        let sessionDescriptor = FetchDescriptor<SmokingSession>()
        let settingsDescriptor = FetchDescriptor<EnvironmentSettings>()
        
        // Perform fetches on main actor to ensure thread safety
        await MainActor.run {
            do {
                _ = try fetch(userDescriptor)
                _ = try fetch(humidorDescriptor)
                _ = try fetch(cigarDescriptor)
                _ = try fetch(purchaseDescriptor)
                _ = try fetch(reviewDescriptor)
                _ = try fetch(sessionDescriptor)
                _ = try fetch(settingsDescriptor)
            } catch {
                CloudKitManager.shared.logDebug(
                    "Error refreshing data: \(error.localizedDescription)",
                    level: .error,
                    error: error
                )
            }
        }
    }
} 