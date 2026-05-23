//
//  HapticManager.swift
//  TheLightUI
//

import UIKit

/// Haptic feedback helpers for SwiftUI interactions.
enum HapticManager {
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        runOnMain {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    }
    
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat = 1.0) {
        runOnMain {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        }
    }
    
    static func selection() {
        runOnMain {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    private static func runOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
