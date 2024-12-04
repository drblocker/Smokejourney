import SwiftUI
import SwiftData

@MainActor
class SmokingSessionManager: ObservableObject {
    static let shared = SmokingSessionManager()
    
    @Published var currentSession: SmokingSession?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var lastEndedCigar: Cigar?
    @Published var lastSessionDuration: TimeInterval = 0
    
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
        // Setup background task handling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Save current state
        if let session = currentSession {
            session.lastBackgroundDate = Date()
            session.totalElapsedTime = elapsedTime
        }
    }
    
    @objc private func appWillEnterForeground() {
        // Update elapsed time based on background duration
        if let session = currentSession,
           let backgroundDate = session.lastBackgroundDate {
            let backgroundDuration = Date().timeIntervalSince(backgroundDate)
            elapsedTime += backgroundDuration
            session.totalElapsedTime = elapsedTime
            session.lastBackgroundDate = nil
        }
        
        // End background task
        endBackgroundTask()
        
        // Restart timer if session was running
        if isRunning {
            startTimer()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
        checkForExistingSession()
    }
    
    private func checkForExistingSession() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SmokingSession>(
                predicate: #Predicate<SmokingSession> { session in
                    session.isActive
                }
            )
            
            if let activeSession = try modelContext.fetch(descriptor).first {
                currentSession = activeSession
                if activeSession.isActive {
                    if let startTime = activeSession.startTime {
                        elapsedTime = activeSession.totalElapsedTime + (activeSession.pausedTime ?? 0)
                    }
                    startTimer()
                }
            }
        } catch {
            print("Error checking for existing session: \(error)")
        }
    }
    
    func startNewSession(cigar: Cigar) {
        endCurrentSession()
        
        guard let modelContext = modelContext else { return }
        
        let session = SmokingSession(cigar: cigar)
        session.startTime = Date()
        session.isActive = true
        session.totalElapsedTime = 0
        
        modelContext.insert(session)
        currentSession = session
        elapsedTime = 0
        startTimer()
    }
    
    func pauseSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        if let session = currentSession {
            session.isActive = false
            session.totalElapsedTime = elapsedTime
            session.pausedTime = elapsedTime
        }
    }
    
    func resumeSession() {
        guard let session = currentSession else { return }
        session.isActive = true
        startTimer()
    }
    
    func resumeExistingSession(_ session: SmokingSession) {
        currentSession = session
        if let startTime = session.startTime {
            elapsedTime = session.totalElapsedTime + (session.pausedTime ?? 0)
        }
        session.isActive = true
        startTimer()
    }
    
    func endCurrentSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        if let session = currentSession {
            session.isActive = false
            session.totalElapsedTime = elapsedTime
            lastEndedCigar = session.cigar
            lastSessionDuration = elapsedTime
            modelContext?.delete(session)
        }
        
        currentSession = nil
        elapsedTime = 0
        ActiveSmokingState.shared.endSession()
    }
    
    private func startTimer() {
        isRunning = true
        timer?.invalidate() // Invalidate any existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            
            if let session = self.currentSession {
                session.totalElapsedTime = self.elapsedTime
            }
        }
        
        // Make timer run in background
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func formattedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
} 