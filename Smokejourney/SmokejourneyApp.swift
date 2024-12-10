//
//  SmokeJourneyApp.swift
//  Smokejourney
//
//  Created by Jason on 11/30/24.
//

import SwiftUI
import SwiftData
import Foundation
import UserNotifications
import os.log
import CoreData

// MARK: - App
@main
struct SmokeJourneyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @StateObject private var homeKitManager = HomeKitManager.shared
    private let logger = Logger(subsystem: "com.smokejourney", category: "App")
    
    let container: ModelContainer
    
    init() {
        let appLogger = Logger(subsystem: "com.smokejourney", category: "App")
        appLogger.debug("Starting app initialization")
        
        do {
            // Use app group container for shared storage
            guard let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.jason.smokejourney"
            )?.appendingPathComponent("smokejourney.store") else {
                throw NSError(domain: "com.smokejourney", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Could not create store URL"])
            }
            
            appLogger.debug("Using store at: \(groupURL.path)")
            
            // Create schema
            let schema = Schema([
                User.self,
                Humidor.self,
                Cigar.self,
                CigarPurchase.self,
                Review.self,
                SmokingSession.self,
                EnvironmentSettings.self
            ])
            
            // Create configuration with CloudKit sync
            let config = ModelConfiguration(
                "SmokeJourney",
                schema: schema,
                url: groupURL,
                allowsSave: true,
                cloudKitDatabase: .private("iCloud.com.jason.smokejourney")
            )
            
            // Initialize container
            container = try ModelContainer(
                for: User.self,
                Humidor.self,
                Cigar.self,
                CigarPurchase.self,
                Review.self,
                SmokingSession.self,
                EnvironmentSettings.self,
                configurations: config
            )
            
            // Set up main context with autosave
            container.mainContext.autosaveEnabled = true
            
            // Add notification observer for saves
            NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: container.mainContext,
                queue: .main
            ) { notification in
                appLogger.debug("💾 Context saved, triggering CloudKit sync")
            }
            
            appLogger.debug("ModelContainer created successfully")
            
        } catch {
            appLogger.error("Failed to create ModelContainer: \(error.localizedDescription)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        appLogger.debug("App initialization completed")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .modelContainer(container)
                        .task {
                            // Verify CloudKit access when app becomes active
                            do {
                                try await CloudKitManager.shared.verifyCloudKitAccess()
                            } catch {
                                print("CloudKit verification failed: \(error.localizedDescription)")
                            }
                            await homeKitManager.checkAuthorizationStatus()
                        }
                } else {
                    LoginView(isAuthenticated: $authManager.isAuthenticated)
                        .modelContainer(container)
                }
            }
            .environmentObject(authManager)
            .environmentObject(sessionManager)
            .task {
                // Restore user state on app launch
                authManager.restoreUser(from: container.mainContext)
            }
        }
        .modelContainer(container)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "VIEW_TEMPERATURE", "VIEW_HUMIDITY":
            // Handle viewing details - you can post a notification to show the relevant view
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowEnvironmentDetails"),
                object: nil,
                userInfo: userInfo
            )
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
