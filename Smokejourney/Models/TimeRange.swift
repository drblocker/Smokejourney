import Foundation

enum TimeRange: String, CaseIterable, Hashable {
    case day = "24h"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var limit: Int {
        switch self {
        case .day: return 24 * 6  // Every 10 minutes
        case .week: return 7 * 24  // Hourly
        case .month: return 30 * 24  // Hourly
        case .year: return 365  // Daily
        }
    }
    
    var strideBy: Calendar.Component {
        switch self {
        case .day: return .minute
        case .week: return .hour
        case .month: return .day
        case .year: return .weekOfMonth
        }
    }
    
    var strideInterval: Int {
        switch self {
        case .day: return 10 // 10 minutes
        case .week: return 1 // 1 hour
        case .month: return 1 // 1 day
        case .year: return 1 // 1 week
        }
    }
    
    var dateFormat: Date.FormatStyle {
        switch self {
        case .day:
            return .dateTime.hour().minute()
        case .week:
            return .dateTime.weekday().hour()
        case .month:
            return .dateTime.month().day()
        case .year:
            return .dateTime.month().day()
        }
    }
    
    var chartXAxisFormat: Date.FormatStyle {
        switch self {
        case .day:
            return .dateTime.hour()
        case .week:
            return .dateTime.weekday()
        case .month:
            return .dateTime.day()
        case .year:
            return .dateTime.month()
        }
    }
} 