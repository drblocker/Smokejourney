import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var syncMonitor: SyncMonitor
    
    var body: some View {
        HStack {
            Image(systemName: syncMonitor.syncStatus.icon)
                .foregroundColor(syncMonitor.syncStatus.color)
                .imageScale(.small)
            
            if case .syncing = syncMonitor.syncStatus {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .help(syncStatusText)
        .alert("Sync Error", isPresented: .constant(syncMonitor.lastSyncError != nil)) {
            Button("OK") {
                syncMonitor.lastSyncError = nil
            }
        } message: {
            if let error = syncMonitor.lastSyncError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var syncStatusText: String {
        if let lastSync = syncMonitor.lastSyncDate {
            return "Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))"
        }
        return "Not yet synced"
    }
} 