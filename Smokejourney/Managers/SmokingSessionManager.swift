import SwiftUI
import SwiftData
import os.log

@MainActor
class SmokingSessionManager: ObservableObject {
    static let shared = SmokingSessionManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "SmokingSessionManager")
    
    private var modelContext: ModelContext?
    private var currentSession: SmokingSession?
    
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var elapsedTime: TimeInterval = 0
    @Published private(set) var activeCigar: Cigar?
    @Published private(set) var lastEndedCigar: Cigar?
    @Published private(set) var lastSessionDuration: TimeInterval = 0
    
    private var timer: Timer?
    
    private init() {}
    
    func initialize(with context: ModelContext) {
        logger.debug("Initializing SmokingSessionManager with context")
        self.modelContext = context
    }
    
    func start() {
        isRunning = true
        isPaused = false
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func endCurrentSession() {
        logger.debug("Ending current session")
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        lastSessionDuration = elapsedTime
        lastEndedCigar = activeCigar
        currentSession?.isActive = false
        activeCigar = nil
        elapsedTime = 0
        logger.debug("Session ended successfully")
    }
    
    func hasActiveSession(for cigar: Cigar) -> Bool {
        let hasSession = currentSession?.cigar?.id == cigar.id && isRunning
        logger.debug("Checking active session for cigar \(cigar.name ?? "unknown"): \(hasSession)")
        return hasSession
    }
    
    func clearLastEndedSession() {
        lastEndedCigar = nil
        lastSessionDuration = 0
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
        }
    }
    
    func formattedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func resumeExistingSession(_ session: SmokingSession) {
        currentSession = session
        activeCigar = session.cigar
        elapsedTime = session.totalElapsedTime
        isRunning = session.isActive
        if isRunning {
            startTimer()
        }
    }
    
    func startSession(with cigar: Cigar) {
        logger.debug("Starting session for cigar: \(cigar.name ?? "unknown")")
        let session = SmokingSession(cigar: cigar)
        session.isActive = true
        currentSession = session
        activeCigar = cigar
        modelContext?.insert(session)
        start()
    }
} 