//
//  SmokeJourneyApp.swift
//  Smokejourney
//
//  Created by Jason on 11/30/24.
//

import SwiftUI
import SwiftData
import Foundation

// MARK: - App
@main
struct SmokeJourneyApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var sessionManager = SmokingSessionManager.shared
    
    let container: ModelContainer
    
    init() {
        // Create the model container
        do {
            container = try ModelContainer(
                for: User.self,
                    Humidor.self,
                    Cigar.self,
                    CigarPurchase.self,
                    Review.self,
                    SmokingSession.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView(isAuthenticated: $authManager.isAuthenticated)
                }
            }
            .environmentObject(authManager)
            .environmentObject(sessionManager)
        }
        .modelContainer(container)
    }
}
