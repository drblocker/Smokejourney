import SwiftUI
import SwiftData
import os.log

@MainActor
final class SmokingSessionManager: ObservableObject {
    static let shared = SmokingSessionManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "SmokingSession")
    
    @Published private(set) var currentSession: SmokingSession?
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var lastEndedCigar: Cigar?
    @Published private(set) var lastSessionDuration: TimeInterval = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var modelContext: ModelContext?
    
    private init() {
        clearAllState()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func startSession(with cigar: Cigar) {
        clearAllState() // Ensure clean state
        
        let session = SmokingSession(cigar: cigar)
        session.isActive = true
        session.startTime = Date()
        
        // Save to SwiftData
        modelContext?.insert(session)
        try? modelContext?.save()
        
        self.currentSession = session
        self.startTime = Date()
        self.isRunning = true
        saveState()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        
        logger.debug("Started session for cigar: \(cigar.name ?? "Unknown")")
    }
    
    func endCurrentSession() {
        guard let session = self.currentSession else { return }
        
        let finalElapsedTime = self.elapsedTime
        let finalCigar = session.cigar
        
        // Update SwiftData model
        session.isActive = false
        session.totalElapsedTime = finalElapsedTime
        try? modelContext?.save()
        
        self.timer?.invalidate()
        self.timer = nil
        self.lastEndedCigar = finalCigar
        self.lastSessionDuration = finalElapsedTime
        
        clearAllState()
        
        logger.debug("Session ended successfully - Duration: \(finalElapsedTime), Cigar: \(finalCigar?.name ?? "Unknown")")
    }
    
    private func clearAllState() {
        // Clear any existing active sessions in SwiftData
        if let context = modelContext {
            let descriptor = FetchDescriptor<SmokingSession>(
                predicate: #Predicate<SmokingSession> { session in
                    session.isActive
                }
            )
            if let activeSessions = try? context.fetch(descriptor) {
                for session in activeSessions {
                    session.isActive = false
                    session.totalElapsedTime = self.elapsedTime
                }
                try? context.save()
            }
        }
        
        self.currentSession = nil
        self.isRunning = false
        self.isPaused = false
        self.elapsedTime = 0
        self.lastEndedCigar = nil
        self.lastSessionDuration = 0
        self.timer?.invalidate()
        self.timer = nil
        self.startTime = nil
        self.pausedTime = 0
        
        UserDefaults.standard.removeObject(forKey: "sessionIsRunning")
        logger.debug("All state cleared")
    }
    
    private func saveState() {
        // Only save running state if we have an active session
        if self.currentSession != nil {
            UserDefaults.standard.set(self.isRunning, forKey: "sessionIsRunning")
        } else {
            UserDefaults.standard.removeObject(forKey: "sessionIsRunning")
        }
    }
    
    func initialize() {
        // Always start fresh
        clearAllState()
        logger.debug("SmokingSessionManager initialized")
    }
    
    func clearLastEndedSession() {
        clearAllState()
        logger.debug("Cleared session state completely")
    }
    
    func pause() {
        self.isPaused = true
        saveState()
    }
    
    func resume() {
        self.isPaused = false
        saveState()
    }
    
    func formattedTime() -> String {
        let hours = Int(self.elapsedTime) / 3600
        let minutes = Int(self.elapsedTime) / 60 % 60
        let seconds = Int(self.elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func hasActiveSession(for cigar: Cigar) -> Bool {
        // Only return true if we have a current session that's actually running
        guard let currentCigar = self.currentSession?.cigar,
              currentCigar.id == cigar.id,
              self.isRunning else {
            return false
        }
        return true
    }
    
    private func updateElapsedTime() {
        guard let start = self.startTime else { return }
        if self.isPaused {
            self.pausedTime += 1
        } else {
            self.elapsedTime = Date().timeIntervalSince(start) - self.pausedTime
        }
    }
} 