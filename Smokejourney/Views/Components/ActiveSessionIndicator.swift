import SwiftUI

struct ActiveSessionIndicator: View {
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showSession = false
    
    var body: some View {
        if sessionManager.isRunning || sessionManager.elapsedTime > 0 {
            Button(action: { showSession = true }) {
                VStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .modifier(PulseAnimation())
                    Text(sessionManager.formattedTime())
                        .font(.caption)
                        .monospacedDigit()
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 3)
            }
            .sheet(isPresented: $showSession) {
                if let cigar = sessionManager.currentSession?.cigar {
                    SmokingSessionView(cigar: cigar)
                }
            }
        }
    }
} 