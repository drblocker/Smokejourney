import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case hour = "1h"
    case day = "24h"
    case week = "7d"
    case month = "30d"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .hour: return "1 Hour"
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        }
    }
    
    var limit: Int {
        switch self {
        case .hour: return 60    // 1 reading per minute
        case .day: return 288    // 5-minute intervals
        case .week: return 168   // 1-hour intervals
        case .month: return 720  // 1-hour intervals
        }
    }
    
    var chartXAxisFormat: Date.FormatStyle {
        switch self {
        case .hour:
            return .dateTime.hour().minute()
        case .day:
            return .dateTime.hour()
        case .week, .month:
            return .dateTime.weekday(.abbreviated)
        }
    }
}

// MARK: - Chart Helpers
extension TimeRange {
    var chartInterval: TimeInterval {
        switch self {
        case .hour:
            return 60           // 1 minute
        case .day:
            return 300         // 5 minutes
        case .week, .month:
            return 3600        // 1 hour
        }
    }
    
    var timeSpan: TimeInterval {
        switch self {
        case .hour:
            return 3600           // 1 hour in seconds
        case .day:
            return 86400         // 24 hours in seconds
        case .week:
            return 604800        // 7 days in seconds
        case .month:
            return 2592000       // 30 days in seconds
        }
    }
    
    func startDate(from endDate: Date = Date()) -> Date {
        endDate.addingTimeInterval(-timeSpan)
    }
} 