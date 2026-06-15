//
//  MessageDateFormatting.swift
//  TheLightUI
//

import Foundation

enum MessageDateFormatting {
    static func compactDateTime(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, \(date.formatted(.dateTime.hour().minute()))"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(.dateTime.hour().minute()))"
        }

        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }
}
