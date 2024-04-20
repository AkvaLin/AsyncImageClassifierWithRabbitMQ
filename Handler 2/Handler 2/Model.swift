//
//  Model.swift
//  Handler 1
//
//  Created by Никита Пивоваров on 20.04.2024.
//

import Foundation
import AppKit

struct Model: Identifiable {
    let id = UUID()
    let image: NSImage
    let name: String
    let prediction: String
}
