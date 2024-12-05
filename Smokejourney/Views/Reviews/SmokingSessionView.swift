import SwiftUI
import SwiftData
import os.log

struct SmokingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cigar: Cigar
    
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @StateObject private var activeState = ActiveSmokingState.shared
    @State private var navigationPath = NavigationPath()
    @State private var finalDuration: TimeInterval = 0
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "SmokingSession")
    
    private func endSession() {
        logger.debug("Stop button tapped")
        
        // Store duration before ending session
        finalDuration = sessionManager.elapsedTime
        
        // End session managers
        sessionManager.endCurrentSession()
        activeState.endSession()
        
        logger.debug("Session ended, duration: \(finalDuration)")
        
        // Navigate to review
        navigationPath.append("review")
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 30) {
                // Timer Display
                Text(sessionManager.formattedTime())
                    .font(.system(size: 64, weight: .medium, design: .monospaced))
                    .padding()
                
                // Cigar Info
                VStack(spacing: 10) {
                    Text("\(cigar.brand ?? "") - \(cigar.name ?? "")")
                        .font(.title2)
                    Text("\(cigar.size ?? "") • \(cigar.wrapperType ?? "")")
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
                
                // Timer Controls
                HStack(spacing: 40) {
                    if sessionManager.isRunning {
                        Button(action: endSession) {
                            Label("Stop", systemImage: "stop.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if sessionManager.isPaused {
                                sessionManager.resume()
                            } else {
                                sessionManager.pause()
                            }
                        }) {
                            Label(sessionManager.isPaused ? "Resume" : "Pause",
                                  systemImage: sessionManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button(action: {
                            sessionManager.startSession(with: cigar)
                            activeState.startSession(cigar: cigar)
                        }) {
                            Label("Start", systemImage: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Smoking Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { route in
                if route == "review" {
                    AddReviewView(
                        cigar: cigar,
                        smokingDuration: finalDuration,
                        onDismiss: {
                            navigationPath.removeLast()
                            dismiss()
                        }
                    )
                    .navigationBarBackButtonHidden()
                }
            }
        }
    }
}