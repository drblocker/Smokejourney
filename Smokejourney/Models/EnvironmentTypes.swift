import SwiftUI

// MARK: - Environmental Monitoring Types
enum EnvironmentalMonitoring {
    // MARK: - Alert Types
    enum AlertType {
        case temperatureLow
        case temperatureHigh
        case humidityLow
        case humidityHigh
        
        var icon: String {
            switch self {
            case .temperatureHigh: return "thermometer.sun.fill"
            case .temperatureLow: return "thermometer.snowflake"
            case .humidityHigh: return "humidity.fill"
            case .humidityLow: return "humidity"
            }
        }
        
        var color: Color {
            switch self {
            case .temperatureHigh, .humidityHigh: return .red
            case .temperatureLow, .humidityLow: return .blue
            }
        }
    }
    
    // MARK: - Alert Model
    struct Alert: Identifiable {
        let id = UUID()
        let type: AlertType
        let message: String
        let timestamp: Date
    }
    
    // MARK: - Status Types
    enum Status {
        case normal
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .normal: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
}

// Type aliases for backward compatibility and easier access
typealias EnvironmentAlert = EnvironmentalMonitoring.Alert
typealias EnvironmentAlertType = EnvironmentalMonitoring.AlertType
typealias EnvironmentStatus = EnvironmentalMonitoring.Status 