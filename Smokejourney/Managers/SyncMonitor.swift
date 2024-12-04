import SwiftUI
import SwiftData
import Combine
import BackgroundTasks
import CoreData

@MainActor
class SyncMonitor: ObservableObject {
    @Published var syncStatus: SyncStatus = .upToDate
    @Published var lastSyncError: Error?
    @Published var lastSyncDate: Date?
    
    static let backgroundTaskIdentifier = "com.jason.smokejourney.sync"
    
    enum SyncStatus {
        case upToDate
        case syncing
        case error
        
        var icon: String {
            switch self {
            case .upToDate: return "checkmark.circle"
            case .syncing: return "arrow.triangle.2.circlepath"
            case .error: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .upToDate: return .green
            case .syncing: return .blue
            case .error: return .red
            }
        }
    }
    
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSyncMonitoring()
    }
    
    func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background sync: \(error)")
        }
    }
    
    private func setupSyncMonitoring() {
        NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.handleSyncEvent(notification)
            }
            .store(in: &cancellables)
        
        scheduleBackgroundSync()
    }
    
    private func handleSyncEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] 
                as? NSPersistentCloudKitContainer.Event else { return }
        
        Task { @MainActor in
            switch event.type {
            case .setup:
                syncStatus = .syncing
            case .import:
                syncStatus = .syncing
            case .export:
                syncStatus = .syncing
            @unknown default:
                break
            }
            
            if event.endDate != nil {
                if event.succeeded {
                    syncStatus = .upToDate
                    lastSyncDate = Date()
                } else if let error = event.error {
                    syncStatus = .error
                    lastSyncError = error
                }
            }
        }
    }
} 