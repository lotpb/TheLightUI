//
//  Date+Helpers.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/4/21.
//

//import Foundation
//import SwiftUI

//extension Date {
//    func descriptiveString(dateStyle: DateFormatter.Style = .short) -> String {
//        let daysBetween = daysBetween(date: Date())
//
//        switch daysBetween {
//        case 0:
//            return "Today"
//        case 1:
//            return "Yesterday"
//        case 2..<5:
//            return Self.weekdayFormatter.string(from: self)
//        default:
//            let formatter = DateFormatter()
//            formatter.dateStyle = dateStyle
//            return formatter.string(from: self)
//        }
//    }

//    func daysBetween(date: Date) -> Int {
//        let calendar = Calendar.current
//        let startDate = calendar.startOfDay(for: self)
//        let endDate = calendar.startOfDay(for: date)
//        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
//    }

//    private static let weekdayFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "EEEE"
//        return formatter
//    }()
//}


