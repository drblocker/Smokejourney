import Foundation
import os.log

enum SensorPushError: LocalizedError {
    case authenticationFailed(message: String)
    case invalidResponse
    case networkError(Error)
    case invalidToken
    case rateLimitExceeded
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidToken:
            return "Invalid or expired token"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

// Request/Response models matching the API exactly
struct AuthRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let code: String?
    let authorization: String?
    let message: String?
    let status: String?
    
    var authToken: String {
        // Try both possible fields for the auth token
        return code ?? authorization ?? ""
    }
}

struct TokenRequest: Codable {
    let authorization: String
}

struct TokenResponse: Codable {
    let accesstoken: String
    let exp: Int?
    let nbf: Double?
    let type: String?
    let iat: Int?
    let iss: String?
    let sub: String?
    
    var effectiveToken: String {
        return accesstoken
    }
}

actor SensorPushService {
    static let shared = SensorPushService()
    private let baseURL = "https://api.sensorpush.com/api/v1"
    private let logger = Logger(subsystem: "com.jason.smokejourney", category: "SensorPush")
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let accessTokenKey = "sensorpush.accessToken"
    private let lastRequestTimeKey = "sensorpush.lastRequestTime"
    
    private var accessToken: String? {
        get { defaults.string(forKey: accessTokenKey) }
        set { defaults.set(newValue, forKey: accessTokenKey) }
    }
    
    private var lastRequestTime: Date? {
        get { defaults.object(forKey: lastRequestTimeKey) as? Date }
        set { defaults.set(newValue, forKey: lastRequestTimeKey) }
    }
    
    private let minimumRequestInterval: TimeInterval = 1
    
    private init() {
        // Restore state from UserDefaults if available
        if let token = defaults.string(forKey: accessTokenKey) {
            self.accessToken = token
            defaults.set(true, forKey: "sensorPushAuthenticated")
        }
    }
    
    func authenticate(email: String, password: String) async throws -> String {
        do {
            // Step 1: Get authorization code
            let authRequest = AuthRequest(email: email, password: password)
            let authURL = URL(string: "\(baseURL)/oauth/authorize")!
            
            var request = URLRequest(url: authURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let requestData = try encoder.encode(authRequest)
            
            // Log request details
            logger.debug("Auth Request URL: \(authURL.absoluteString)")
            logger.debug("Auth Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let requestString = String(data: requestData, encoding: .utf8) {
                logger.debug("Auth Request Body: \(requestString)")
            }
            
            request.httpBody = requestData
            
            let (authData, authResponse) = try await URLSession.shared.data(for: request)
            
            // Log raw response for debugging
            if let responseString = String(data: authData, encoding: .utf8) {
                logger.debug("Raw Auth Response: \(responseString)")
            }
            
            guard let httpResponse = authResponse as? HTTPURLResponse else {
                throw SensorPushError.invalidResponse
            }
            
            logger.debug("Auth Response Status Code: \(httpResponse.statusCode)")
            logger.debug("Auth Response Headers: \(httpResponse.allHeaderFields)")
            
            guard httpResponse.statusCode == 200 else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: authData) {
                    throw SensorPushError.authenticationFailed(message: errorResponse.message)
                }
                throw SensorPushError.authenticationFailed(message: "Authentication failed with status \(httpResponse.statusCode)")
            }
            
            // Try to decode the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase // Handle both camelCase and snake_case
            
            let authResult = try decoder.decode(AuthResponse.self, from: authData)
            
            guard !authResult.authToken.isEmpty else {
                throw SensorPushError.authenticationFailed(message: "No authorization token in response")
            }
            
            // Step 2: Exchange authorization code for access token
            let tokenRequest = TokenRequest(authorization: authResult.authToken)
            let tokenURL = URL(string: "\(baseURL)/oauth/accesstoken")!
            
            var tokenReq = URLRequest(url: tokenURL)
            tokenReq.httpMethod = "POST"
            tokenReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            tokenReq.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let tokenRequestData = try encoder.encode(tokenRequest)
            
            // Log token request details
            logger.debug("Token Request URL: \(tokenURL.absoluteString)")
            logger.debug("Token Request Headers: \(tokenReq.allHTTPHeaderFields ?? [:])")
            if let tokenRequestString = String(data: tokenRequestData, encoding: .utf8) {
                logger.debug("Token Request Body: \(tokenRequestString)")
            }
            
            tokenReq.httpBody = tokenRequestData
            
            let (tokenData, tokenResponse) = try await URLSession.shared.data(for: tokenReq)
            
            guard let httpTokenResponse = tokenResponse as? HTTPURLResponse else {
                throw SensorPushError.invalidResponse
            }
            
            logger.debug("Token Response Status Code: \(httpTokenResponse.statusCode)")
            logger.debug("Token Response Headers: \(httpTokenResponse.allHeaderFields)")
            
            if let rawResponse = String(data: tokenData, encoding: .utf8) {
                logger.debug("Raw Token Response Body: \(rawResponse)")
            }
            
            guard httpTokenResponse.statusCode == 200 else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: tokenData) {
                    throw SensorPushError.authenticationFailed(message: errorResponse.message)
                }
                throw SensorPushError.authenticationFailed(message: "Token request failed with status \(httpTokenResponse.statusCode)")
            }
            
            do {
                let tokenResult = try decoder.decode(TokenResponse.self, from: tokenData)
                self.accessToken = tokenResult.effectiveToken
                defaults.set(true, forKey: "sensorPushAuthenticated")
                return tokenResult.effectiveToken
            } catch let decodingError as DecodingError {
                logger.error("Decoding error details: \(String(describing: decodingError))")
                if let rawResponse = String(data: tokenData, encoding: .utf8) {
                    logger.debug("Failed to decode response: \(rawResponse)")
                }
                throw SensorPushError.decodingError("Failed to decode response: \(decodingError.localizedDescription)")
            }
            
        } catch {
            logger.error("Authentication error: \(String(describing: error))")
            throw error
        }
    }
    
    func signOut() {
        accessToken = nil
        lastRequestTime = nil
        defaults.set(false, forKey: "sensorPushAuthenticated")
    }
    
    // MARK: - API Requests
    func getSensors() async throws -> [SensorPushDevice] {
        guard let token = accessToken else {
            throw SensorPushError.invalidToken
        }
        
        try await checkRateLimit()
        
        let url = URL(string: "\(baseURL)/devices/sensors")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"  // Changed back to POST per API docs
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") // Add "Bearer " prefix
        
        // Add empty body as required by API
        let emptyBody = try JSONEncoder().encode(EmptyRequest())
        request.httpBody = emptyBody
        
        // Log request details for debugging
        logger.debug("Sensors Request URL: \(url.absoluteString)")
        logger.debug("Sensors Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("Sensors Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SensorPushError.invalidResponse
        }
        
        logger.debug("Sensors Response Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SensorPushError.authenticationFailed(message: errorResponse.message)
            }
            throw SensorPushError.authenticationFailed(message: "Failed to fetch sensors with status \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let sensorResponse = try decoder.decode([String: SensorPushDevice].self, from: data)
        
        // Convert the dictionary response to our Sensor array
        return sensorResponse.map { (id, details) in
            SensorPushDevice(
                id: id,
                name: details.name,
                deviceId: details.deviceId,
                type: details.type,
                batteryVoltage: details.batteryVoltage,
                rssi: details.rssi,
                active: details.active
            )
        }
    }
    
    func getSamples(limit: Int = 20) async throws -> [SensorSample] {
        guard let token = accessToken else {
            throw SensorPushError.invalidToken
        }
        
        try await checkRateLimit()
        
        let url = URL(string: "\(baseURL)/samples")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create request body
        let requestBody = [
            "limit": limit
        ]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Log request for debugging
        logger.debug("Samples Request URL: \(url.absoluteString)")
        logger.debug("Samples Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let requestString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            logger.debug("Samples Request Body: \(requestString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("Samples Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SensorPushError.invalidResponse
        }
        
        logger.debug("Samples Response Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SensorPushError.authenticationFailed(message: errorResponse.message)
            }
            throw SensorPushError.authenticationFailed(message: "Failed to fetch samples with status \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let sampleResponse = try decoder.decode(SampleResponse.self, from: data)
        
        // Convert to array of samples - take first sensor's samples
        return sampleResponse.sensors.values.first ?? []
    }
    
    // MARK: - Helper Methods
    private func checkRateLimit() async throws {
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            // Instead of throwing error, just wait
            let waitTime = minimumRequestInterval - Date().timeIntervalSince(lastRequest)
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
    
    // Add method to get a specific sensor
    func getSensor(id: String) async throws -> SensorPushDevice? {
        let sensors = try await getSensors()
        return sensors.first { $0.id == id }
    }
}

// MARK: - Models
struct EmptyRequest: Encodable {
    // Empty struct for encoding empty request bodies
}

struct SensorPushDevice: Codable, Identifiable {
    let id: String
    let name: String
    let deviceId: String
    let type: String
    let batteryVoltage: Double
    let rssi: Int
    let active: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case deviceId = "device_id"
        case type
        case batteryVoltage = "battery_voltage"
        case rssi
        case active
    }
}

struct SampleResponse: Codable {
    let last_time: String
    let sensors: [String: [SensorSample]]
    let truncated: Bool
    let status: String
    let total_samples: Int
    let total_sensors: Int
}

struct SensorSample: Codable {
    let observed: String
    let gateways: String
    let temperature: Double
    let humidity: Double
    let dewpoint: Double
    let vpd: Double
    let altitude: Double
    
    var timestamp: Date {
        ISO8601DateFormatter().date(from: observed) ?? Date()
    }
}

struct ErrorResponse: Codable {
    let message: String
    let status: String?
}

// Add these model structs for the sensors endpoint
struct SensorResponse: Codable {
    let sensors: [String: SensorPushDevice]
}

struct SensorDetails: Codable {
    let name: String
    let id: String
    let deviceId: String
    let type: String
    let batteryVoltage: Double
    let rssi: Int
    let active: Bool
    let calibration: CalibrationData
    let alerts: AlertSettings
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case deviceId = "deviceId"
        case type
        case batteryVoltage = "battery_voltage"
        case rssi
        case active
        case calibration
        case alerts
        case address
    }
}

struct CalibrationData: Codable {
    let humidity: Double
    let temperature: Double
}

struct AlertSettings: Codable {
    let temperature: AlertThreshold
    let humidity: AlertThreshold
}

struct AlertThreshold: Codable {
    let enabled: Bool
    let max: Double
    let min: Double
} 