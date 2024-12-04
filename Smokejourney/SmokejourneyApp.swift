//
//  SmokejourneyApp.swift
//  Smokejourney
//
//  Created by Jason on 11/30/24.
//

import SwiftUI
import SwiftData
import BackgroundTasks
import CloudKit

@main
struct SmokejourneyApp: App {
    let container: ModelContainer
    private let cloudKitManager = CloudKitManager.shared
    private let backgroundTaskManager = BackgroundTaskHandler.shared
    @State private var showCloudKitError = false
    @State private var cloudKitError: CloudKitError?
    
    init() {
        do {
            // Setup configuration
            let configuration = cloudKitManager.setupModelConfiguration()
            
            // Initialize container with unwrapped schema
            if let schema = configuration.schema {
                container = try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
                
                // Configure background tasks after container setup
                backgroundTaskManager.setupBackgroundTasks()
            } else {
                fatalError("Failed to get schema from configuration")
            }
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    do {
                        try await cloudKitManager.verifyiCloudAccount()
                    } catch let error as CloudKitError {
                        cloudKitError = error
                        showCloudKitError = true
                    } catch {
                        cloudKitError = .serverError(error)
                        showCloudKitError = true
                    }
                }
                .alert("iCloud Sync Error",
                       isPresented: $showCloudKitError,
                       presenting: cloudKitError) { error in
                    Button("Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    Button("OK", role: .cancel) { }
                } message: { error in
                    Text(error.errorDescription ?? "Unknown error")
                }
        }
    }
}
