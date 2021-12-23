//
//  Date+Helpers.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/4/21.
//

import Foundation
import SwiftUI

///WelcomeView, LoadingView, WeatherUI, WeatherRow
extension Date {

    func descriptiveString(dateStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle

        let daysBetween = self.daysBetween(date: Date())

        if daysBetween == 0 {
            return "today"
        }
        else if daysBetween == 1 {
            return "Yesterday"
        }
        else if daysBetween < 5 {
            let weekdayIndex = Calendar.current.component(.weekday, from: self) - 1
            return formatter.weekdaySymbols[weekdayIndex]
        }
        return formatter.string(from: self)
    }

    func daysBetween(date: Date) -> Int {
        let calender = Calendar.current
        let date1 = calender.startOfDay(for: self)
        let date2 = calender.startOfDay(for: date)
        if let daysBetween = calender.dateComponents([.day], from: date1, to: date2).day {
            return daysBetween
        }
        return 0
    }

//    private var formattedDate: DateFormatter {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .full
//        return dateFormatter
//    }
//
//    func asShortDateString() -> String {
//        return formattedDate.string(from: self)
//    }
}

extension Color {
    static let background = Color(hue: 0.654, saturation: 0.78, brightness: 0.442)
    static let text = Color(hue: 1.0, saturation: 0.0, brightness: 0.888)
}



