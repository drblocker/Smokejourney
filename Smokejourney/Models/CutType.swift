import Foundation

enum CutType: String, Codable, CaseIterable {
    case guillotine = "Guillotine"
    case vCut = "V-Cut"
    case punch = "Punch"
    
    var description: String {
        switch self {
        case .guillotine:
            return "Clean straight cut across the cap"
        case .vCut:
            return "V-shaped notch in the cap"
        case .punch:
            return "Round hole in the cap"
        }
    }
}

@objc(CutTypeValueTransformer)
final class CutTypeValueTransformer: ValueTransformer {
    static let name = NSValueTransformerName("CutTypeValueTransformer")
    
    static func register() {
        let transformer = CutTypeValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    override class func transformedValueClass() -> AnyClass {
        NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cutType = value as? CutType else { return nil }
        return cutType.rawValue
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else { return nil }
        return CutType(rawValue: string)
    }
} 