//
//  MessageDateFormatting.swift
//  TheLightUI
//

import Foundation

enum MessageDateFormatting {
    static func weekdayAndTime(for date: Date, relativeTo referenceDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate

        if date < sevenDaysAgo {
            return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
        }

        return date.formatted(.dateTime.weekday(.wide).hour().minute())
    }

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
