import Foundation
import CloudKit

enum CloudKitSchema {
    static let schemaVersion = "1.0"
    
    static let recordTypes = [
        "User",
        "Humidor",
        "Cigar",
        "CigarPurchase",
        "Review",
        "SmokingSession",
        "EnvironmentSettings"
    ]
    
    static func setupSchema() -> CKRecordZone {
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone")
        return CKRecordZone(zoneID: zoneID)
    }
} 