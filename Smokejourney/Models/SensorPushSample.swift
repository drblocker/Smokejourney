import Foundation

struct SensorPushSample: Codable {
    let time: Date
    let temperature: Double
    let humidity: Double
    
    enum CodingKeys: String, CodingKey {
        case time = "timestamp"
        case temperature
        case humidity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle date decoding from ISO8601 string
        let dateString = try container.decode(String.self, forKey: .time)
        if let date = ISO8601DateFormatter().date(from: dateString) {
            self.time = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Date string does not match expected format")
        }
        
        self.temperature = try container.decode(Double.self, forKey: .temperature)
        self.humidity = try container.decode(Double.self, forKey: .humidity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode date as ISO8601 string
        let dateString = ISO8601DateFormatter().string(from: time)
        try container.encode(dateString, forKey: .time)
        
        try container.encode(temperature, forKey: .temperature)
        try container.encode(humidity, forKey: .humidity)
    }
} 