//
//  Item.swift
//  OpenBox
//
//  Created by jianliang on 2026/1/24.
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
