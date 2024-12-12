import Foundation
import SwiftUI

// MARK: - Models
struct SensorPushDevice: Identifiable, Codable {
    let id: String
    let deviceId: String
    let name: String?
    let location: String?
    let active: Bool
    let batteryVoltage: Double
    let rssi: Int
    
    var displayName: String {
        return name ?? deviceId
    }
}

struct SensorSample: Codable {
    let time: Date
    let temperature: Double
    let humidity: Double
}

enum SensorPushError: LocalizedError {
    case unauthorized
    case invalidCredentials
    case networkError(Error)
    case invalidResponse
    case unknown
    case authenticationFailed(message: String)
    case scanningFailed
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Not authorized. Please sign in."
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unknown:
            return "An unknown error occurred"
        case .authenticationFailed(let message):
            return message
        case .scanningFailed:
            return "Failed to scan for sensors"
        case .connectionFailed:
            return "Failed to connect to sensor"
        }
    }
}

@MainActor
final class SensorPushService: ObservableObject {
    static let shared = SensorPushService()
    
    @Published var isAuthorized = false
    @Published var sensors: [SensorPushDevice] = []
    @Published var isLoading = false
    
    private let api = SensorPushAPI()
    private let keychain = KeychainWrapper.standard
    
    func authenticate(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await api.authenticate(email: email, password: password)
            isAuthorized = true
            keychain.set(email, forKey: "sensorPushEmail")
            keychain.set(password, forKey: "sensorPushPassword")
        } catch {
            throw SensorPushError.invalidCredentials
        }
    }
    
    func signOut() {
        isAuthorized = false
        keychain.removeObject(forKey: "sensorPushEmail")
        keychain.removeObject(forKey: "sensorPushPassword")
        api.clearAuth()
    }
    
    func getSensors() async throws -> [SensorPushDevice] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            sensors = try await api.fetchSensors()
            return sensors
        } catch {
            throw SensorPushError.networkError(error)
        }
    }
    
    func getSamples(for sensorId: String, limit: Int = 1) async throws -> [SensorSample] {
        do {
            return try await api.fetchSamples(for: sensorId, limit: limit)
        } catch {
            throw SensorPushError.networkError(error)
        }
    }
    
    func scanForSensors() async throws -> Bool {
        // Simulate scanning for now - replace with actual SensorPush API implementation
        do {
            // Add artificial delay to simulate scanning
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2 seconds
            
            // Here you would:
            // 1. Start Bluetooth scanning
            // 2. Look for SensorPush devices
            // 3. Update the sensors array with found devices
            
            // For testing, simulate finding a sensor 50% of the time
            let foundSensor = Bool.random()
            if foundSensor {
                let newSensor = SensorPushDevice(
                    id: UUID().uuidString,
                    deviceId: "SP-TEST",
                    name: "Test Sensor",
                    location: nil,
                    active: true,
                    batteryVoltage: 0.0,
                    rssi: 0
                )
                sensors.append(newSensor)
            }
            
            return foundSensor
        } catch {
            throw SensorPushError.scanningFailed
        }
    }
}

// MARK: - API Client
private class SensorPushAPI {
    private let baseURL = URL(string: "https://api.sensorpush.com/api/v1")!
    private var authToken: String?
    
    func clearAuth() {
        authToken = nil
    }
    
    func authenticate(email: String, password: String) async throws {
        let authURL = baseURL.appendingPathComponent("oauth/authorize")
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let token = try JSONDecoder().decode([String: String].self, from: data)["access_token"] else {
            throw SensorPushError.invalidCredentials
        }
        
        authToken = token
    }
    
    func fetchSensors() async throws -> [SensorPushDevice] {
        guard let authToken else { throw SensorPushError.unauthorized }
        
        let url = baseURL.appendingPathComponent("devices/sensors")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SensorPushError.invalidResponse
        }
        
        return try JSONDecoder().decode([SensorPushDevice].self, from: data)
    }
    
    func fetchSamples(for sensorId: String, limit: Int) async throws -> [SensorSample] {
        guard let authToken else { throw SensorPushError.unauthorized }
        
        let url = baseURL.appendingPathComponent("samples")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct SamplesRequest: Encodable {
            let sensors: [String]
            let limit: Int
        }
        
        let requestBody = SamplesRequest(sensors: [sensorId], limit: limit)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SensorPushError.invalidResponse
        }
        
        return try JSONDecoder().decode([SensorSample].self, from: data)
    }
}