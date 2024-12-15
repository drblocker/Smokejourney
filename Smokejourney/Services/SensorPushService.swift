import Foundation
import os.log

@MainActor
final class SensorPushService: ObservableObject {
    static let shared = SensorPushService()
    private let logger = Logger(subsystem: "com.smokejourney", category: "SensorPush")
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = false
    @Published private(set) var sensors: [SensorPushDevice] = []
    @Published private(set) var latestSamples: [String: SensorKit.SensorReading] = [:]
    
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "sensorPushAuthToken") }
        set { UserDefaults.standard.set(newValue, forKey: "sensorPushAuthToken") }
    }
    
    private let baseURL = URL(string: "https://api.sensorpush.com/api/v1")!
    private let session = URLSession.shared
    
    private init() {
        isAuthorized = authToken != nil
    }
    
    func fetchSensors() async throws {
        guard let token = authToken else {
            throw SensorError.unauthorized
        }
        
        let sensorsURL = baseURL.appendingPathComponent("devices/sensors")
        var request = URLRequest(url: sensorsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        sensors = try JSONDecoder().decode([SensorPushDevice].self, from: data)
        
        // Fetch initial readings for each sensor
        for device in sensors {
            if let reading = try await fetchLatestReading(for: device.id) {
                latestSamples[device.id] = reading
            }
        }
    }
    
    func fetchLatestReading(for deviceId: String) async throws -> SensorKit.SensorReading? {
        let samples = try await fetchSamples(for: deviceId, from: Date().addingTimeInterval(-300), limit: 1)
        guard let sample = samples.first else { return nil }
        
        return SensorKit.SensorReading(
            timestamp: sample.time,
            temperature: sample.temperature,
            humidity: sample.humidity
        )
    }
    
    func fetchSamples(for deviceId: String, from: Date, limit: Int = 100) async throws -> [SensorPushSample] {
        guard let token = authToken else {
            throw SensorError.unauthorized
        }
        
        let samplesURL = baseURL.appendingPathComponent("samples")
        var request = URLRequest(url: samplesURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = SampleQuery(
            sensors: [deviceId],
            startTime: from,
            stopTime: Date(),
            limit: limit
        )
        request.httpBody = try JSONEncoder().encode(query)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([SensorPushSample].self, from: data)
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // First, get an authorization token
        let authRequest = AuthRequest(email: email, password: password)
        let authURL = baseURL.appendingPathComponent("oauth/authorize")
        
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(authRequest)
        
        let (authData, _) = try await session.data(for: request)
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: authData)
        
        // Then, use the authorization token to get an access token
        let accessURL = baseURL.appendingPathComponent("oauth/accesstoken")
        request = URLRequest(url: accessURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["authorization": authResponse.authorization])
        
        let (accessData, _) = try await session.data(for: request)
        let accessResponse = try JSONDecoder().decode(AccessResponse.self, from: accessData)
        
        authToken = accessResponse.accesstoken
        isAuthorized = true
        
        // Fetch sensors after successful authentication
        try await fetchSensors()
    }
    
    func signOut() {
        authToken = nil
        isAuthorized = false
        sensors = []
    }
}

// MARK: - Supporting Types
private struct AuthRequest: Codable {
    let email: String
    let password: String
}

private struct AuthResponse: Codable {
    let authorization: String
}

private struct AccessResponse: Codable {
    let accesstoken: String
}

private struct SampleQuery: Codable {
    let sensors: [String]
    let startTime: Date
    let stopTime: Date
    let limit: Int
    
    enum CodingKeys: String, CodingKey {
        case sensors
        case startTime = "time_start"
        case stopTime = "time_stop"
        case limit
    }
}