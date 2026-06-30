//
//  AppBadgeManager.swift
//  TheLightUI
//

import UIKit

protocol AppBadgeManaging {
    @MainActor var badgeNumber: Int { get }
    @MainActor func clearBadge()
}

struct LiveAppBadgeManager: AppBadgeManaging {
    var badgeNumber: Int {
        UserDefaults.standard.integer(forKey: "badgeNumber")
    }

    func clearBadge() {
        UserDefaults.standard.set(0, forKey: "badgeNumber")

        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error {
                print("Failed to clear badge: \(error)")
            }
        }
    }
}

struct PreviewAppBadgeManager: AppBadgeManaging {
    var badgeNumber: Int { 0 }

    func clearBadge() { }
}
