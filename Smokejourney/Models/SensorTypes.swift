import Foundation

// Create a namespace for our sensor types
enum SensorKit {
    // Unified reading type
    struct SensorReading: Identifiable {
        let id = UUID()
        let timestamp: Date
        let temperature: Double  // Fahrenheit
        let humidity: Double     // Percentage
    }
    
    enum SensorType: String {
        case sensorPush
        case homeKit
    }
} 