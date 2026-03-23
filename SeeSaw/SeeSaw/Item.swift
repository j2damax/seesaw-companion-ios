//
//  Item.swift
//  SeeSaw
//
//  Created by Jayampathy Balasuriya on 2026-03-23.
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
