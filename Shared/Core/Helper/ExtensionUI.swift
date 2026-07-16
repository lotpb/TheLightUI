//
//  ExtensionUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 5/25/21.
//

// Utility helpers for phone calls.

import SwiftUI

extension OpenURLAction {
    /// Attempts to initiate a phone call by converting a raw string into a tel:// URL and opening it.
    /// Safely no-ops if the string can't be converted.
    func callPhoneNumber(_ rawValue: String) {
        guard let url = PhoneNumber(raw: rawValue).url else { return }
        self(url)
    }
}


