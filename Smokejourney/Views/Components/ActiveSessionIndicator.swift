import SwiftUI

struct ActiveSessionIndicator: View {
    @StateObject private var sessionManager = SmokingSessionManager.shared
    let cigar: Cigar
    
    var body: some View {
        if sessionManager.hasActiveSession(for: cigar) {
            Circle()
                .fill(Color.orange)
                .frame(width: 10, height: 10)
                .modifier(PulseAnimation())
        }
    }
} 