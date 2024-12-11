import SwiftUI
import HomeKit
import os

@MainActor
final class HomeStore: NSObject, ObservableObject, HMHomeManagerDelegate {
    static let shared = HomeStore()
    private let logger = Logger(subsystem: "com.smokejourney", category: "HomeKit")
    private let isDebugEnabled = true // Keep HomeKit debugging enabled for now
    
    @Published var primaryHome: HMHome?
    @Published var accessories: [HMAccessory] = []
    @Published var rooms: [HMRoom] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var homeManagerState: HomeManagerState = .initializing
    @Published var authorizationStatus: HMHomeManagerAuthorizationStatus = .determined
    
    enum HomeManagerState {
        case initializing
        case failed(Error)
        case noHome
        case available(HMHome)
    }
    
    let homeManager: HMHomeManager
    
    private var retryCount = 0
    private let maxRetries = 3
    
    private override init() {
        self.homeManager = HMHomeManager()
        super.init()
        self.homeManager.delegate = self
        
        // Initialize HomeKit with retry mechanism
        Task {
            await initializeHomeKit()
        }
    }
    
    private func initializeHomeKit() async {
        logDebug("Initializing HomeKit...")
        
        // Wait for home manager to be ready
        for _ in 0..<5 { // Wait up to 5 seconds for initial setup
            if homeManager.homes != nil {
                await checkAuthorizationStatus()
                return
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // If we get here, try to reinitialize
        if retryCount < maxRetries {
            retryCount += 1
            logDebug("Retrying HomeKit initialization (attempt \(retryCount)/\(maxRetries))")
            
            // Create a new home manager instance
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds before retry
                await initializeHomeKit()
            }
        } else {
            logDebug("HomeKit initialization failed after \(maxRetries) attempts")
            homeManagerState = .failed(NSError(
                domain: "HomeKit",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Unable to connect to HomeKit. Please try restarting the app."
                ]
            ))
        }
    }
    
    private func logDebug(_ message: String, error: Error? = nil) {
        guard isDebugEnabled else { return }
        
        if let error = error {
            logger.error("HomeKit: \(message): \(error.localizedDescription)")
        } else {
            logger.debug("HomeKit: \(message)")
        }
    }
    
    private func checkAuthorizationStatus() async {
        logDebug("Checking HomeKit authorization status...")
        
        // Check if HomeKit is available
        guard HMHomeManager().homes != nil else {
            homeManagerState = .failed(NSError(
                domain: "HomeKit",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "HomeKit service is not available. Please check your device settings."
                ]
            ))
            return
        }
        
        authorizationStatus = homeManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorized:
            logDebug("HomeKit authorized, checking for homes")
            handleHomeManagerUpdate()
            
        case .determined:
            // Wait briefly and check again
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await checkAuthorizationStatus()
            
        case .restricted:
            homeManagerState = .failed(NSError(
                domain: "HomeKit",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "HomeKit access is restricted on this device."
                ]
            ))
            
        default:
            homeManagerState = .failed(NSError(
                domain: "HomeKit",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Please enable HomeKit access in Settings and make sure you're signed into iCloud."
                ]
            ))
        }
    }
    
    // MARK: - HMHomeManagerDelegate
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task {
            retryCount = 0 // Reset retry count on successful update
            await checkAuthorizationStatus()
        }
    }
    
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        handleHomeManagerUpdate()
    }
    
    // MARK: - Home Management
    func createHome(named name: String) async throws -> HMHome {
        isLoading = true
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMHome, Error>) in
            homeManager.addHome(withName: name) { home, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let home = home {
                    continuation.resume(returning: home)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "HomeKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create home"]
                    ))
                }
            }
        }
    }
    
    func addAccessory(to home: HMHome) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addAndSetupAccessories { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleHomeManagerUpdate() {
        logDebug("Handling home manager update...")
        
        if let home = homeManager.primaryHome {
            logDebug("Found primary home: \(home.name)")
            primaryHome = home
            accessories = home.accessories
            rooms = home.rooms
            homeManagerState = .available(home)
            home.delegate = self
            
        } else if let firstHome = homeManager.homes.first {
            logDebug("No primary home, using first available home: \(firstHome.name)")
            homeManager.updatePrimaryHome(firstHome) { [weak self] error in
                Task { @MainActor in
                    if let error = error {
                        self?.logDebug("Failed to set primary home", error: error)
                        self?.homeManagerState = .failed(error)
                    } else {
                        self?.primaryHome = firstHome
                        self?.accessories = firstHome.accessories
                        self?.rooms = firstHome.rooms
                        self?.homeManagerState = .available(firstHome)
                        firstHome.delegate = self
                    }
                }
            }
        } else {
            logDebug("No homes found")
            homeManagerState = .noHome
        }
    }
}

// MARK: - HMHomeDelegate
extension HomeStore: HMHomeDelegate {
    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        guard home == primaryHome else { return }
        accessories = home.accessories
    }
    
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        guard home == primaryHome else { return }
        accessories = home.accessories
    }
    
    func home(_ home: HMHome, didAdd room: HMRoom) {
        guard home == primaryHome else { return }
        rooms = home.rooms
    }
}

struct HomeKitSetupView: View {
    @EnvironmentObject private var homeKitManager: HomeKitService
    @Environment(\.dismiss) private var dismiss
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if homeKitManager.isAuthorized && homeKitManager.currentHome != nil {
                    // Show successful setup
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 60))
                        
                        Text("HomeKit Connected")
                            .font(.title2)
                            .bold()
                        
                        Text("Connected to home: \(homeKitManager.currentHome?.name ?? "")")
                            .foregroundColor(.secondary)
                        
                        Button("Done") {
                            onComplete(true)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Show error state
                    VStack(spacing: 20) {
                        Text("HomeKit Error")
                            .foregroundColor(.red)
                            .font(.title2)
                            .bold()
                        
                        Text("Please enable HomeKit access in Settings and make sure you're signed into iCloud.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("HomeKit Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete(false)
                        dismiss()
                    }
                }
            }
            .task {
                await homeKitManager.checkAuthorization()
            }
        }
    }
}

struct AccessoryRow: View {
    let accessory: HMAccessory
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(accessory.name)
                .font(.headline)
            Text(accessory.manufacturer ?? "Unknown Manufacturer")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AddAccessoryView: View {
    let home: HMHome
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeStore = HomeStore.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Scan the HomeKit code on your humidor or enter it manually.")
                    .padding()
                
                Button {
                    Task {
                        do {
                            try await homeStore.addAccessory(to: home)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                } label: {
                    Label("Add Accessory", systemImage: "plus.viewfinder")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Add Accessory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeKitSetupView(onComplete: { _ in })
            .environmentObject(HomeKitService.shared)
    }
}