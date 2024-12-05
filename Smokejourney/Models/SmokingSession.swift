import SwiftData
import Foundation

@Model
final class SmokingSession {
    var cigar: Cigar?
    
    var startTime: Date?
    var pausedTime: TimeInterval?
    var isActive: Bool = false
    var totalElapsedTime: TimeInterval = 0
    var lastBackgroundDate: Date?
    
    init(cigar: Cigar) {
        self.cigar = cigar
        self.startTime = Date()
        self.isActive = false
        self.totalElapsedTime = 0
    }
} 
