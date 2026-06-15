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
        UIApplication.shared.applicationIconBadgeNumber
    }

    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

struct PreviewAppBadgeManager: AppBadgeManaging {
    var badgeNumber: Int { 0 }

    func clearBadge() { }
}
