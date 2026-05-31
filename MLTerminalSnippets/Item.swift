//
//  Item.swift
//  MLTerminalSnippets
//
//  Created by Michel Anderson Lutz Teixeira on 31/05/26.
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
