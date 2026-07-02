//
//  ExpenseModels.swift
//  TheLightUI
//

import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var categoryRawValue: String
    var date: Date
    var notes: String
    var isReimbursable: Bool

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        notes: String = "",
        isReimbursable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryRawValue = category.rawValue
        self.date = date
        self.notes = notes
        self.isReimbursable = isReimbursable
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case meals = "Meals"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case software = "Software"
    case supplies = "Supplies"
    case utilities = "Utilities"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .food:
            "cart"
        case .meals:
            "fork.knife"
        case .travel:
            "car.fill"
        case .entertainment:
            "tv.fill"
        case .software:
            "desktopcomputer"
        case .supplies:
            "shippingbox.fill"
        case .utilities:
            "bolt.fill"
        case .other:
            "tag.fill"
        }
    }
}

enum ExpenseSortOrder: String, CaseIterable, Identifiable {
    case date = "Date"
    case name = "Name"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .date:
            "calendar"
        case .name:
            "textformat"
        }
    }
}

enum ExpenseDateRange: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case allTime = "All Time"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .thisMonth:
            "calendar"
        case .lastMonth:
            "calendar.badge.clock"
        case .allTime:
            "infinity"
        }
    }

    func includes(_ date: Date) -> Bool {
        switch self {
        case .allTime:
            return true
        case .thisMonth:
            return Calendar.current.isDate(date, equalTo: .now, toGranularity: .month)
        case .lastMonth:
            guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now) else {
                return false
            }
            return Calendar.current.isDate(date, equalTo: lastMonth, toGranularity: .month)
        }
    }
}

enum ExpenseFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reimbursable = "Reimbursable"
    case personal = "Personal"

    var id: String { rawValue }

    func includes(_ expense: Expense) -> Bool {
        switch self {
        case .all:
            true
        case .reimbursable:
            expense.isReimbursable
        case .personal:
            !expense.isReimbursable
        }
    }
}
