import SwiftUI
import SwiftData

struct SmokingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cigar: Cigar
    
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @StateObject private var activeState = ActiveSmokingState.shared
    @State private var showStopConfirmation = false
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
                        Button(action: {
                            showStopConfirmation = true
                        }) {
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
            .navigationDestination(isPresented: $navigateToReview) {
                AddReviewView(cigar: cigar, smokingDuration: finalDuration)
                    .navigationBarBackButtonHidden(true)
            }
            .confirmationDialog(
                "End Smoking Session?",
                isPresented: $showStopConfirmation,
                titleVisibility: .visible
            ) {
                Button("Review", role: .destructive) {
                    finalDuration = sessionManager.elapsedTime
                    sessionManager.endCurrentSession()
                    activeState.endSession()
                    navigateToReview = true
                }
                Button("Skip Review", role: .none) {
                    // Create smoke record without review
                    let smoke = CigarPurchase(
                        quantity: -1,
                        price: nil,
                        vendor: nil,
                        url: nil,
                        type: .smoke
                    )
                    smoke.date = Date()
                    smoke.cigar = cigar
                    
                    if cigar.purchases == nil {
                        cigar.purchases = []
                    }
                    cigar.purchases?.append(smoke)
                    
                    // End the session
                    sessionManager.endCurrentSession()
                    activeState.endSession()
                    
                    // Dismiss back to cigar detail view
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Would you like to review this smoking session?")
            }
        }
    }
} 