import SwiftUI
import SwiftData

@Model
final class Review {
    // Basic Info
    var date: Date?
    var smokingDuration: TimeInterval?
    var ageAtSmoking: TimeInterval?
    var isPrivate: Bool?
    var notes: String?
    var photosData: Data?
    var environment: String?
    var pairings: String?
    @Attribute(.transformable(by: CutTypeValueTransformer.self))
    var cutType: CutType?
    var humidity: Double?
    
    // Ratings (1-5 scale)
    var appearanceRating: AppearanceRating?
    var aromaRating: AromaRating?
    var constructionRating: ConstructionRating?
    var drawRating: DrawRating?
    var flavorRating: FlavorRating?
    var burnRating: BurnRating?
    var ashRating: AshRating?
    var strengthRating: StrengthRating?
    var consistencyRating: ConsistencyRating?
    var finishRating: FinishRating?
    var overallRating: OverallRating?
    
    // Relationships
    var cigar: Cigar?
    
    init(date: Date = Date()) {
        self.date = date
        self.isPrivate = false
    }
    
    // Computed Properties
    var effectiveDate: Date {
        date ?? Date()
    }
    
    var effectiveIsPrivate: Bool {
        isPrivate ?? false
    }
    
    var averageRating: Double {
        let ratings: [Double] = [
            appearanceRating?.score ?? 0,
            aromaRating?.score ?? 0,
            constructionRating?.score ?? 0,
            drawRating?.score ?? 0,
            flavorRating?.score ?? 0,
            burnRating?.score ?? 0,
            ashRating?.score ?? 0,
            strengthRating?.score ?? 0,
            consistencyRating?.score ?? 0,
            finishRating?.score ?? 0,
            overallRating?.score ?? 0
        ]
        
        let validRatings = ratings.filter { $0 > 0 }
        guard !validRatings.isEmpty else { return 0 }
        return validRatings.reduce(0, +) / Double(validRatings.count)
    }
    
    var photos: [Data]? {
        get {
            guard let data = photosData else { return nil }
            do {
                // Use secure coding for better security and future compatibility
                let decoder = JSONDecoder()
                return try decoder.decode([Data].self, from: data)
            } catch {
                print("Error decoding photos: \(error)")
                return nil
            }
        }
        set {
            do {
                if let newValue = newValue {
                    let encoder = JSONEncoder()
                    photosData = try encoder.encode(newValue)
                } else {
                    photosData = nil
                }
            } catch {
                print("Error encoding photos: \(error)")
                photosData = nil
            }
        }
    }
}

// Detailed Rating Structures
struct AppearanceRating: Codable {
    var wrapperColorConsistency: Int // 1-5
    var surfaceTexture: Int // 1-5
    var visibleVeins: Int // 1-5
    var overallConstruction: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(wrapperColorConsistency + surfaceTexture + visibleVeins + overallConstruction) / 4.0
    }
}

struct AromaRating: Codable {
    var preLightScent: Int // 1-5
    var footAroma: Int // 1-5
    var coldDrawNotes: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(preLightScent + footAroma + coldDrawNotes) / 3.0
    }
}

struct ConstructionRating: Codable {
    var firmnessConsistency: Int // 1-5
    var capApplication: Int // 1-5
    var wrapperIntegrity: Int // 1-5
    var visibleDefects: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(firmnessConsistency + capApplication + wrapperIntegrity + visibleDefects) / 4.0
    }
}

struct DrawRating: Codable {
    var resistanceLevel: Int // 1-5
    var smokeProduction: Int // 1-5
    var drawConsistency: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(resistanceLevel + smokeProduction + drawConsistency) / 3.0
    }
}

struct FlavorRating: Codable {
    var complexity: Int
    var flavorTransitions: Int
    var flavorIntensity: Int
    var tasteNotesString: String?
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case complexity
        case flavorTransitions
        case flavorIntensity
        case tasteNotesString
        case notes
    }
    
    var score: Double {
        Double(complexity + flavorTransitions + flavorIntensity) / 3.0
    }
    
    // Computed property to handle the array conversion
    var tasteNotes: [String] {
        get {
            tasteNotesString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        }
        set {
            tasteNotesString = newValue.joined(separator: ",")
        }
    }
    
    init(complexity: Int, flavorTransitions: Int, flavorIntensity: Int, tasteNotes: [String], notes: String? = nil) {
        self.complexity = complexity
        self.flavorTransitions = flavorTransitions
        self.flavorIntensity = flavorIntensity
        self.tasteNotesString = tasteNotes.joined(separator: ",")
        self.notes = notes
    }
}

struct BurnRating: Codable {
    var burnLineEvenness: Int // 1-5
    var touchUpsNeeded: Int // 1-5
    var tunneling: Int // 1-5
    var burnRate: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(burnLineEvenness + touchUpsNeeded + tunneling + burnRate) / 4.0
    }
}

struct AshRating: Codable {
    var color: Int // 1-5
    var firmness: Int // 1-5
    var stackConsistency: Int // 1-5
    var holdLength: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(color + firmness + stackConsistency + holdLength) / 4.0
    }
}

struct StrengthRating: Codable {
    var body: Int // 1-5
    var nicotineImpact: Int // 1-5
    var progression: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(body + nicotineImpact + progression) / 3.0
    }
}

struct ConsistencyRating: Codable {
    var flavorStability: Int // 1-5
    var drawMaintenance: Int // 1-5
    var performanceReliability: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(flavorStability + drawMaintenance + performanceReliability) / 3.0
    }
}

struct FinishRating: Codable {
    var aftertasteQuality: Int // 1-5
    var flavorEvolution: Int // 1-5
    var finishLength: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(aftertasteQuality + flavorEvolution + finishLength) / 3.0
    }
}

struct OverallRating: Codable {
    var valueForMoney: Int // 1-5
    var enjoymentLevel: Int // 1-5
    var wouldSmokeAgain: Int // 1-5
    var recommendationLevel: Int // 1-5
    var notes: String?
    
    var score: Double {
        Double(valueForMoney + enjoymentLevel + wouldSmokeAgain + recommendationLevel) / 4.0
    }
}

// Add this transformer class
final class CutTypeTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cutType = value as? CutType else { return nil }
        return cutType.rawValue
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else { return nil }
        return CutType(rawValue: string)
    }
} 