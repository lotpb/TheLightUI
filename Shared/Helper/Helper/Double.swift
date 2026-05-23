//
//  Double.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import Foundation

extension Double {
    /// Converts a Double into currency text with 2 decimal places.
    /// Example: 1234.56 -> "$1,234.56"
    func asCurrencyWith2Decimals() -> String {
        Self.currencyFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// Converts a Double into string representation with 2 decimal places.
    /// Example: 1.2345 -> "1.23"
    func asNumberString() -> String {
        string(decimals: 2)
    }

    /// WeatherUI App
    func string(decimals: Int = 0) -> String {
        String(format: "%.*f", decimals, self)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension Int {
    var formatted: String {
        Self.decimalFormatter.string(from: NSNumber(value: self)) ?? ""
    }

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}
