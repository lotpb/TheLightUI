//
//  ColorOptions.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/7/22.
//

import SwiftUI

// Custom colors used by the Furniture and list row views.
enum CustomColor {
    static let linenColor = Color(#colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.937254902, alpha: 1))
    static let gradColors = [Color(#colorLiteral(red: 0.2942537963, green: 0.55384022, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.9546096921, green: 0.5026705861, blue: 1, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.7779054046, blue: 0.9874657989, alpha: 1)), Color(#colorLiteral(red: 0.6243117452, green: 1, blue: 0.9114550352, alpha: 1)), Color(#colorLiteral(red: 0.454975009, green: 0.6753683686, blue: 1, alpha: 1))]

    // Furniture theme palette.
    static let furnitureInk = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let furnitureSecondaryInk = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let furnitureAccent = Color(red: 0.12, green: 0.55, blue: 0.52)
    static let furnitureCoral = Color(red: 0.90, green: 0.45, blue: 0.36)
    static let furnitureControl = Color.white.opacity(0.72)
}
//LoadingView
extension Color {
    static let background = Color(hue: 0.654, saturation: 0.78, brightness: 0.442)
    static let text = Color(hue: 1.0, saturation: 0.0, brightness: 0.888)
}


