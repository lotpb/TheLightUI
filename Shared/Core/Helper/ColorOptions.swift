//
//  ColorOptions.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/7/22.
//

import SwiftUI


//struct ColorOptions {
//    static var all: [Color] = [
//        .primary,
//        .gray,
//        .red,
//        .orange,
//        .yellow,
//        .green,
//        .mint,
//        .cyan,
//        .indigo,
//        .purple
//    ]
//    
//    static var `default` : Color = Color.primary
//    
//    static func random() -> Color {
//        if let element = ColorOptions.all.randomElement() {
//            return element
//        } else {
//            return .primary
//        }
//    }
//}

//Furniture, KistRowView
struct CustomColor {
    
    static let linenColor = Color(#colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.937254902, alpha: 1))
    static let gradColors = [Color(#colorLiteral(red: 0.2942537963, green: 0.55384022, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.9546096921, green: 0.5026705861, blue: 1, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.7779054046, blue: 0.9874657989, alpha: 1)), Color(#colorLiteral(red: 0.6243117452, green: 1, blue: 0.9114550352, alpha: 1)), Color(#colorLiteral(red: 0.454975009, green: 0.6753683686, blue: 1, alpha: 1))]
}
//LoadingView
extension Color {
    static let background = Color(hue: 0.654, saturation: 0.78, brightness: 0.442)
    static let text = Color(hue: 1.0, saturation: 0.0, brightness: 0.888)
}


