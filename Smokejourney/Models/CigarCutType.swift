import Foundation

// MARK: - Enum Definition
@objc(SmokejourneyAppCutType)
public enum CutType: Int, Codable {
    case guillotine = 0
    case vCut = 1
    case punch = 2
    case straight = 3
    case natural = 4
    
    var stringValue: String {
        switch self {
        case .guillotine: return "Guillotine"
        case .vCut: return "V-Cut"
        case .punch: return "Punch"
        case .straight: return "Straight Cut"
        case .natural: return "Natural"
        }
    }
}

// MARK: - Value Transformer
@objc(CutTypeValueTransformer)
final class CutTypeValueTransformer: ValueTransformer {
    static let transformerName = NSValueTransformerName("CutTypeValueTransformer")
    
    static func registerTransformer() {
        let transformer = CutTypeValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: transformerName)
    }
    
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cutType = value as? CutType else { return nil }
        let dict = ["rawValue": cutType.rawValue]
        return try? JSONSerialization.data(withJSONObject: dict)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data,
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
              let rawValue = dict["rawValue"],
              let cutType = CutType(rawValue: rawValue)
        else {
            return CutType.guillotine
        }
        return cutType
    }
} 