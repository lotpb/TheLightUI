//
//  Double.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import Foundation

extension Double {
    /// Formats the value with a fixed number of fraction digits.
    /// Used by the Weather UI, e.g. 72.6.string() -> "73".
    func string(decimals: Int = 0) -> String {
        String(format: "%.*f", decimals, self)
    }
}
