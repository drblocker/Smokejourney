//
//  Item.swift
//  Smokejourney
//
//  Created by Jason on 11/30/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
