//
//  AppTheme.swift
//  TheLightUI
//

import SwiftUI

enum AppTheme {
    static func accentColor(for storedColor: Int?) -> Color {
        storedColor == 0 ? .purple : .orange
    }
}
