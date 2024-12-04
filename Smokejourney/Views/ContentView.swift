import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isAuthenticated = false
    @StateObject private var sessionManager = SmokingSessionManager.shared
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
            checkExistingUser()
            sessionManager.initialize(with: modelContext)
        }
    }
    
    private func checkExistingUser() {
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            isAuthenticated = !users.isEmpty
        } catch {
            print("Failed to fetch users: \(error)")
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
                ProfileView(isAuthenticated: $isAuthenticated)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .onChange(of: sessionManager.lastEndedCigar) { cigar in
            showReviewSheet = cigar != nil
        }
        .onAppear {
            sessionManager.initialize(with: modelContext)
        }
    }
} 