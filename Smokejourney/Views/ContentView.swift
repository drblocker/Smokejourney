import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isAuthenticated = false
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showReviewSheet = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView(
                    showReviewSheet: $showReviewSheet,
                    isAuthenticated: $isAuthenticated
                )
                .sheet(isPresented: $showReviewSheet) {
                    if let cigar = sessionManager.lastEndedCigar {
                        NavigationStack {
                            AddReviewView(
                                cigar: cigar,
                                smokingDuration: sessionManager.lastSessionDuration
                            )
                            .onDisappear {
                                sessionManager.clearLastEndedSession()
                            }
                        }
                    }
                }
            } else {
                NavigationStack {
                    LoginView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .onAppear {
            authManager.restoreUser(from: modelContext)
            sessionManager.setModelContext(modelContext)
            sessionManager.initialize()
        }
    }
}

struct MainTabView: View {
    @Binding var showReviewSheet: Bool
    @Binding var isAuthenticated: Bool
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NavigationStack {
                HumidorListView()
            }
            .tabItem {
                Label("Humidors", systemImage: "cabinet")
            }
            
            NavigationStack {
                EnvironmentalMonitoringTabView()
            }
            .tabItem {
                Label("Environment", systemImage: "thermometer")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .onChange(of: sessionManager.lastEndedCigar) { cigar in
            showReviewSheet = cigar != nil
        }
        .onAppear {
            sessionManager.initialize()
        }
    }
} 