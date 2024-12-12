import SwiftUI

enum ChartType: String, CaseIterable {
    case line = "Line"
    case scatter = "Scatter"
    case bar = "Bar"
    
    var icon: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .scatter: return "chart.scatter"
        case .bar: return "chart.bar"
        }
    }
} 