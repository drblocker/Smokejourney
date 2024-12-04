import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case hour = "1 Hour"
    case day = "24 Hours"
    case week = "7 Days"
    case month = "30 Days"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var limit: Int {
        switch self {
        case .hour: return 60
        case .day: return 288  // 12 samples per hour * 24
        case .week: return 2016 // 12 samples per hour * 24 * 7
        case .month: return 8640 // 12 samples per hour * 24 * 30
        }
    }
    
    var strideBy: Calendar.Component {
        switch self {
        case .hour: return .minute
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        }
    }
    
    var dateFormat: Date.FormatStyle {
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