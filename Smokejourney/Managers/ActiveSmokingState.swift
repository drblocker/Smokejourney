import SwiftUI
import SwiftData

@MainActor
class ActiveSmokingState: ObservableObject {
    static let shared = ActiveSmokingState()
    
    @Published var activeSession: SmokingSession?
    @Published var activeCigar: Cigar?
    @Published var isActive = false
    
    private init() {}
    
    func startSession(cigar: Cigar) {
        self.activeCigar = cigar
        self.isActive = true
    }
    
    func endSession() {
        self.activeCigar = nil
        self.isActive = false
    }
} 