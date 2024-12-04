import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @State private var showRatingSheet = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                VStack(spacing: 0) {
                    // Active Session Timer Bar - Following Apple HIG for status bars
                    if sessionManager.isRunning || sessionManager.elapsedTime > 0,
                       let cigar = sessionManager.currentSession?.cigar {
                        VStack(spacing: 8) {
                            // Session Info
                            HStack {
                                Label(cigar.brand ?? "", systemImage: "flame.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(cigar.name ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { 
                                    sessionManager.endCurrentSession()
                                    showRatingSheet = true
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Timer Controls
                            HStack {
                                // Timer Display
                                Text(sessionManager.formattedTime())
                                    .font(.system(.title, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Playback Controls
                                HStack(spacing: 24) {
                                    if sessionManager.isRunning {
                                        Button(action: { sessionManager.pauseSession() }) {
                                            Label("Pause", systemImage: "pause.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.orange)
                                        }
                                        .accessibilityLabel("Pause Session")
                                    } else {
                                        Button(action: { sessionManager.resumeSession() }) {
                                            Label("Resume", systemImage: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                        }
                                        .accessibilityLabel("Resume Session")
                                    }
                                    
                                    Button(action: { 
                                        sessionManager.endCurrentSession()
                                        showRatingSheet = true
                                    }) {
                                        Label("End", systemImage: "stop.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    .accessibilityLabel("End Session")
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.2)),
                            alignment: .bottom
                        )
                    }
                    
                    // Main Tab View
                    TabView(selection: $selectedTab) {
                        HumidorListView(modelContext: modelContext)
                            .tabItem {
                                Label("Humidors", systemImage: "cabinet")
                            }
                            .tag(0)
                        
                        ProfileView(isAuthenticated: $isAuthenticated)
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag(1)
                        
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag(2)
                    }
                }
                .sheet(isPresented: $showRatingSheet, onDismiss: {
                    // Clear any remaining session state if needed
                    sessionManager.lastEndedCigar = nil
                    sessionManager.lastSessionDuration = 0
                }) {
                    if let cigar = sessionManager.lastEndedCigar {
                        NavigationStack {
                            AddReviewView(cigar: cigar, smokingDuration: sessionManager.lastSessionDuration)
                        }
                    }
                }
            } else {
                LoginView(isAuthenticated: $isAuthenticated, modelContext: modelContext)
            }
        }
        .onAppear {
            checkExistingUser()
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