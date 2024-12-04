import SwiftUI
import SwiftData

struct SmokingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cigar: Cigar
    
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @StateObject private var activeState = ActiveSmokingState.shared
    @State private var showEndSessionAlert = false
    @State private var navigateToReview = false
    @State private var finalDuration: TimeInterval = 0
    
    var body: some View {
        NavigationStack {
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
                        Button(action: { sessionManager.pauseSession() }) {
                            Image(systemName: "pause.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        .tint(.orange)
                    } else if sessionManager.elapsedTime > 0 {
                        Button(action: { sessionManager.resumeSession() }) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        .tint(.green)
                    } else {
                        Button(action: {
                            sessionManager.startNewSession(cigar: cigar)
                            activeState.startSession(cigar: cigar)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        .tint(.green)
                    }
                    
                    if sessionManager.elapsedTime > 0 {
                        Button(action: { showEndSessionAlert = true }) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        .tint(.red)
                    }
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Smoking Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToReview) {
                AddReviewView(cigar: cigar, smokingDuration: finalDuration)
                    .navigationBarBackButtonHidden(true)
            }
            .onAppear {
                sessionManager.initialize(with: modelContext)
                if let existingSession = try? modelContext.fetch(FetchDescriptor<SmokingSession>())
                    .first(where: { $0.isActive && $0.cigar?.id == cigar.id }) {
                    sessionManager.resumeExistingSession(existingSession)
                    activeState.startSession(cigar: cigar)
                }
            }
            .alert("End Session?", isPresented: $showEndSessionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("End Session", role: .destructive) {
                    finalDuration = sessionManager.elapsedTime
                    sessionManager.endCurrentSession()
                    activeState.endSession()
                    navigateToReview = true
                }
            } message: {
                Text("Would you like to end this smoking session and write a review?")
            }
        }
    }
} 