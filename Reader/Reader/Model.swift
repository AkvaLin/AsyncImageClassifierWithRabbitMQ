//
//  Model.swift
//  Reader
//
//  Created by Никита Пивоваров on 20.04.2024.
//

import Foundation

struct Model: Identifiable {
    let id = UUID()
    let handler: String
    let images: [String]
}
