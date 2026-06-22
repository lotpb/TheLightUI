//
//  AppTheme.swift
//  TheLightUI
//

import SwiftUI

enum AppTheme {
    static func accentColor(for storedColor: Int?) -> Color {
        switch storedColor {
        case 0:
            return .purple
        case 1:
            return .orange
        case 2:
            return .blue
        case 3:
            return .indigo
        default:
            return .purple
        }
    }
}
