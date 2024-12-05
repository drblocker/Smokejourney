import SwiftUI
import SwiftData
import os.log

@MainActor
class SmokingSessionManager: ObservableObject {
    static let shared = SmokingSessionManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "SmokingSessionManager")
    
    private var modelContext: ModelContext?
    private var currentSession: SmokingSession?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var elapsedTime: TimeInterval = 0
    @Published private(set) var activeCigar: Cigar?
    @Published private(set) var lastEndedCigar: Cigar?
    @Published private(set) var lastSessionDuration: TimeInterval = 0
    
    private var timer: Timer?
    private var lastBackgroundDate: Date?
    
    private init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTransition),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundTransition),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleBackgroundTransition() {
        logger.debug("App entering background")
        lastBackgroundDate = Date()
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Save current session state
        if let session = currentSession {
            session.lastBackgroundDate = lastBackgroundDate
            session.totalElapsedTime = elapsedTime
        }
    }
    
    @objc private func handleForegroundTransition() {
        logger.debug("App entering foreground")
        if let backgroundDate = lastBackgroundDate {
            let timeInBackground = Date().timeIntervalSince(backgroundDate)
            if isRunning && !isPaused {
                elapsedTime += timeInBackground
                logger.debug("Added background time: \(timeInBackground)")
            }
        }
        
        endBackgroundTask()
        lastBackgroundDate = nil
        
        // Resume timer if needed
        if isRunning && !isPaused {
            startTimer()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            
            // Update session
            if let session = self.currentSession {
                session.totalElapsedTime = self.elapsedTime
            }
        }
    }
    
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
        currentSession?.totalElapsedTime = elapsedTime
        activeCigar = nil
        elapsedTime = 0
        endBackgroundTask()
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
        session.startTime = Date()
        currentSession = session
        activeCigar = cigar
        modelContext?.insert(session)
        start()
    }
} 