//
//  ExpenseModels.swift
//  TheLightUI
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case meals = "Meals"
    case travel = "Travel"
    case software = "Software"
    case supplies = "Supplies"
    case utilities = "Utilities"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .meals:
            "fork.knife"
        case .travel:
            "car.fill"
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

@available(iOS 17.0, *)
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
