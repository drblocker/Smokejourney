import Foundation
import os.log

class SensorPushService {
    static let shared = SensorPushService()
    private let baseURL = "https://api.sensorpush.com/api/v1"
    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.smokejourney", category: "SensorPush")
    
    // Keys for storing tokens
    private let accessTokenKey = "sensorPushAccessToken"
    private let authTokenKey = "sensorPushAuthToken"
    private let tokenExpiryKey = "sensorPushTokenExpiry"
    
    private var accessToken: String? {
        get { defaults.string(forKey: accessTokenKey) }
        set { defaults.set(newValue, forKey: accessTokenKey) }
    }
    
    private var authToken: String? {
        get { defaults.string(forKey: authTokenKey) }
        set { defaults.set(newValue, forKey: authTokenKey) }
    }
    
    private var tokenExpiry: Date? {
        get { defaults.object(forKey: tokenExpiryKey) as? Date }
        set { defaults.set(newValue, forKey: tokenExpiryKey) }
    }
    
    // MARK: - Authentication
    func authenticate(email: String, password: String) async throws -> String {
        // Step 1: Get authorization token
        let authorizeURL = URL(string: "\(baseURL)/oauth/authorize")!
        var authorizeRequest = URLRequest(url: authorizeURL)
        authorizeRequest.httpMethod = "POST"
        authorizeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authBody = ["email": email, "password": password]
        let authBodyData = try JSONEncoder().encode(authBody)
        authorizeRequest.httpBody = authBodyData
        
        // Log request details (excluding sensitive info)
        logger.debug("Authorization Request - URL: \(authorizeURL.absoluteString)")
        logger.debug("Authorization Request - Headers: \(authorizeRequest.allHTTPHeaderFields ?? [:])")
        
        let (authData, authResponse) = try await URLSession.shared.data(for: authorizeRequest)
        
        // Log response details
        if let responseString = String(data: authData, encoding: .utf8) {
            logger.debug("Authorization Raw Response: \(responseString)")
        }
        
        guard let httpAuthResponse = authResponse as? HTTPURLResponse else {
            logger.error("Invalid response type from authorization request")
            throw SensorPushError.invalidResponse(statusCode: 0, message: "Invalid response type")
        }
        
        logger.debug("Authorization Response Status: \(httpAuthResponse.statusCode)")
        
        guard httpAuthResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: authData) {
                logger.error("Authorization failed: \(errorResponse.message)")
                throw SensorPushError.authenticationFailed(message: errorResponse.message)
            }
            throw SensorPushError.invalidResponse(statusCode: httpAuthResponse.statusCode, message: "Authorization request failed")
        }
        
        // Try to decode the authorization response
        do {
            let authResult = try JSONDecoder().decode(AuthResponse.self, from: authData)
            logger.debug("Successfully decoded authorization token")
            
            // Store auth token
            self.authToken = authResult.authorization
            
            // Step 2: Get access token using authorization
            let accessTokenURL = URL(string: "\(baseURL)/oauth/accesstoken")!
            var tokenRequest = URLRequest(url: accessTokenURL)
            tokenRequest.httpMethod = "POST"
            tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let tokenBody = ["authorization": authResult.authorization]
            let tokenBodyData = try JSONEncoder().encode(tokenBody)
            tokenRequest.httpBody = tokenBodyData
            
            logger.debug("Access Token Request - URL: \(accessTokenURL.absoluteString)")
            let (tokenData, tokenResponse) = try await URLSession.shared.data(for: tokenRequest)
            
            // Log token response
            if let tokenResponseString = String(data: tokenData, encoding: .utf8) {
                logger.debug("Access Token Raw Response: \(tokenResponseString)")
            }
            
            guard let httpTokenResponse = tokenResponse as? HTTPURLResponse else {
                logger.error("Invalid response type from token request")
                throw SensorPushError.invalidResponse(statusCode: 0, message: "Invalid token response type")
            }
            
            logger.debug("Access Token Response Status: \(httpTokenResponse.statusCode)")
            
            guard httpTokenResponse.statusCode == 200 else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: tokenData) {
                    logger.error("Token request failed: \(errorResponse.message)")
                    throw SensorPushError.authenticationFailed(message: errorResponse.message)
                }
                throw SensorPushError.invalidResponse(statusCode: httpTokenResponse.statusCode, message: "Token request failed")
            }
            
            let tokenResult = try JSONDecoder().decode(TokenResponse.self, from: tokenData)
            
            // Store tokens and expiry
            self.accessToken = tokenResult.accessToken
            self.tokenExpiry = Date().addingTimeInterval(30 * 60) // 30 minutes
            defaults.set(true, forKey: "sensorPushAuthenticated")
            
            logger.debug("Successfully authenticated and got access token")
            return tokenResult.accessToken
            
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            if let dataString = String(data: authData, encoding: .utf8) {
                logger.debug("Failed to decode data: \(dataString)")
            }
            throw SensorPushError.decodingError("Failed to decode authentication response: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Token Management
    private func getValidToken() async throws -> String {
        // Check if we have a valid access token
        if let expiry = tokenExpiry,
           let token = accessToken,
           expiry > Date().addingTimeInterval(60) { // Buffer of 1 minute
            return token
        }
        
        // If we have an auth token, try to get a new access token
        if let authToken = authToken {
            let accessTokenURL = URL(string: "\(baseURL)/oauth/accesstoken")!
            var request = URLRequest(url: accessTokenURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let tokenBody = ["authorization": authToken]
            request.httpBody = try JSONEncoder().encode(tokenBody)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let tokenResult = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            self.accessToken = tokenResult.accessToken
            self.tokenExpiry = Date().addingTimeInterval(30 * 60)
            return tokenResult.accessToken
        }
        
        throw SensorPushError.invalidToken
    }
    
    // MARK: - API Methods
    func getSamples(for sensorId: String, limit: Int = 20) async throws -> [SensorSample] {
        let token = try await getValidToken()
        
        let url = URL(string: "\(baseURL)/samples")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        let sampleRequest = SampleRequest(
            limit: limit,
            timestamp: "desc",
            sensors: [sensorId]
        )
        request.httpBody = try JSONEncoder().encode(sampleRequest)
        
        // Log request details
        logger.debug("Samples Request - URL: \(url.absoluteString)")
        logger.debug("Samples Request - Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            logger.debug("Samples Request - Body: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("Samples Raw Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw SensorPushError.invalidResponse(statusCode: 0, message: "Invalid response type")
        }
        
        logger.debug("Samples Response Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                logger.error("API error: \(errorResponse.message)")
                throw SensorPushError.invalidResponse(statusCode: httpResponse.statusCode, message: errorResponse.message)
            }
            throw SensorPushError.invalidResponse(statusCode: httpResponse.statusCode, message: nil)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let sampleResponse = try decoder.decode(SampleResponse.self, from: data)
            logger.debug("Successfully decoded response with last time: \(sampleResponse.last_time)")
            
            guard let samples = sampleResponse.sensors[sensorId] else {
                logger.error("No samples found for sensor ID: \(sensorId)")
                return []
            }
            
            logger.debug("Returning \(samples.count) samples for sensor")
            return samples
        } catch {
            logger.error("Failed to decode samples response: \(error)")
            if let dataString = String(data: data, encoding: .utf8) {
                logger.debug("Failed to decode data: \(dataString)")
            }
            throw SensorPushError.decodingError("Failed to decode samples response: \(error.localizedDescription)")
        }
    }
    
    func getSensors() async throws -> [SensorPushDevice] {
        let token = try await getValidToken()
        
        let url = URL(string: "\(baseURL)/devices/sensors")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        let emptyBody = try JSONEncoder().encode(EmptyRequest())
        request.httpBody = emptyBody
        
        logger.debug("Requesting sensors list")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SensorPushError.invalidResponse(statusCode: 0, message: "Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw SensorPushError.invalidResponse(statusCode: httpResponse.statusCode, message: errorResponse.message)
            }
            throw SensorPushError.invalidResponse(statusCode: httpResponse.statusCode, message: nil)
        }
        
        let sensorDict = try JSONDecoder().decode([String: SensorPushDevice].self, from: data)
        return sensorDict.map { id, device in
            var sensor = device
            sensor.id = id
            return sensor
        }
    }
    
    // Add to SensorPushService class
    func signOut() {
        // Clear all tokens
        accessToken = nil
        authToken = nil
        tokenExpiry = nil
        
        // Clear authentication state
        defaults.removeObject(forKey: accessTokenKey)
        defaults.removeObject(forKey: authTokenKey)
        defaults.removeObject(forKey: tokenExpiryKey)
        defaults.set(false, forKey: "sensorPushAuthenticated")
        
        // Force save changes
        defaults.synchronize()
        
        logger.debug("User signed out, all tokens cleared")
    }
}

// MARK: - Models
struct AuthResponse: Codable {
    let authorization: String
}

struct TokenResponse: Codable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "accesstoken"
    }
}

struct SensorPushDevice: Codable, Identifiable {
    var id: String = ""
    let name: String
    let deviceId: String
    let type: String
    let batteryVoltage: Double
    let rssi: Int
    let active: Bool
    
    enum CodingKeys: String, CodingKey {
        case name
        case deviceId = "deviceId"
        case type
        case batteryVoltage = "battery_voltage"
        case rssi
        case active
    }
}

struct SampleResponse: Codable {
    let last_time: String
    let sensors: [String: [SensorSample]]
}

struct SensorSample: Codable {
    let observed: String  // API returns "observed" as ISO8601 string
    let temperature: Double
    let humidity: Double
    let dewpoint: Double
    let vpd: Double
    let altitude: Int
    let gateways: String?
    
    enum CodingKeys: String, CodingKey {
        case observed
        case temperature
        case humidity
        case dewpoint
        case vpd
        case altitude
        case gateways
    }
    
    // Convert observed string to Date
    var time: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: observed) ?? Date()
    }
}

struct SampleRequest: Codable {
    let limit: Int
    let timestamp: String
    let sensors: [String]
}

struct ErrorResponse: Codable {
    let message: String
    let type: String?
    let statusCode: String?
}

// Empty request for endpoints that don't need a body
struct EmptyRequest: Encodable {}

enum SensorPushError: LocalizedError {
    case invalidToken
    case invalidResponse(statusCode: Int, message: String?)
    case authenticationFailed(message: String)
    case decodingError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "No valid access token available"
        case .invalidResponse(let statusCode, let message):
            return "Invalid response (Status \(statusCode)): \(message ?? "No message")"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}