import Foundation

struct StabilityMetrics {
    let temperature: Double  // 0-1 score
    let humidity: Double    // 0-1 score
    
    static let ideal = StabilityMetrics(temperature: 1.0, humidity: 1.0)
    static let poor = StabilityMetrics(temperature: 0.0, humidity: 0.0)
} 