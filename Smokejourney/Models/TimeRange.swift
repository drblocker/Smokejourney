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
        case .week: return "Week"
        case .month: return "Month"
        }
    }
    
    var limit: Int {
        switch self {
        case .hour: return 60
        case .day: return 24 * 60
        case .week: return 7 * 24 * 60
        case .month: return 30 * 24 * 60
        }
    }
    
    var dateFormat: Date.FormatStyle {
        switch self {
        case .hour:
            return .dateTime.hour().minute()
        case .day:
            return .dateTime.hour()
        case .week:
            return .dateTime.weekday().hour()
        case .month:
            return .dateTime.month().day()
        }
    }
    
    var chartXAxisFormat: Date.FormatStyle {
        switch self {
        case .hour:
            return .dateTime.hour().minute()
        case .day:
            return .dateTime.hour()
        case .week, .month:
            return .dateTime.month().day()
        }
    }
} 