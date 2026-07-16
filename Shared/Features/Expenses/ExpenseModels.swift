//
//  ExpenseModels.swift
//  TheLightUI
//

import Foundation
import SwiftData

/// Shared currency format style derived from the user's current locale.
enum ExpenseFormat {
    static var currency: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var categoryRawValue: String
    var date: Date
    var notes: String
    var isReimbursable: Bool
    /// When this expense was last edited, used to resolve Firebase sync
    /// conflicts (newest edit wins). The `.distantPast` default is what
    /// rows saved before this property existed get on migration, so any
    /// timestamped remote copy wins over them.
    var lastUpdate: Date = Date.distantPast

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = .now,
        notes: String = "",
        isReimbursable: Bool = false,
        lastUpdate: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.categoryRawValue = category.rawValue
        self.date = date
        self.notes = notes
        self.isReimbursable = isReimbursable
        self.lastUpdate = lastUpdate
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}

/// Codable snapshot of an Expense used for JSON import/export.
struct ExpenseRecord: Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String
    var isReimbursable: Bool
    /// Optional so JSON exports written before this field existed still
    /// decode; nil sorts as older than any timestamped copy.
    var lastUpdate: Date?

    init(_ expense: Expense) {
        id = expense.id
        title = expense.title
        amount = expense.amount
        category = expense.category
        date = expense.date
        notes = expense.notes
        isReimbursable = expense.isReimbursable
        lastUpdate = expense.lastUpdate
    }

    func makeExpense() -> Expense {
        Expense(
            id: id,
            title: title,
            amount: amount,
            category: category,
            date: date,
            notes: notes,
            isReimbursable: isReimbursable,
            lastUpdate: lastUpdate ?? .now
        )
    }

    func apply(to expense: Expense) {
        expense.title = title
        expense.amount = amount
        expense.category = category
        expense.date = date
        expense.notes = notes
        expense.isReimbursable = isReimbursable
        expense.lastUpdate = lastUpdate ?? .now
    }
}

extension ExpenseRecord {
    /// Inserts new records into the store and updates existing expenses
    /// matched by id, leaving already-identical ones untouched. Shared by
    /// the tracker's JSON import/Firebase restore and the Settings backup
    /// section.
    ///
    /// With `newerWins` (the automatic Firebase refresh), an incoming record
    /// only replaces an expense edited at the same time or earlier, so a
    /// fetch that races a local edit can't revert it. Without it (explicit
    /// imports and restores), the incoming record always wins.
    static func merge(
        _ records: [ExpenseRecord],
        into context: ModelContext,
        newerWins: Bool = false
    ) throws -> (inserted: Int, updated: Int) {
        let existingExpenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let expensesByID = Dictionary(existingExpenses.map { ($0.id, $0) }) { first, _ in first }
        var inserted = 0
        var updated = 0
        for record in records {
            if let existing = expensesByID[record.id] {
                if newerWins, (record.lastUpdate ?? .distantPast) < existing.lastUpdate {
                    continue
                }
                if ExpenseRecord(existing) != record {
                    record.apply(to: existing)
                    updated += 1
                }
            } else {
                context.insert(record.makeExpense())
                inserted += 1
            }
        }

        try context.save()
        return (inserted, updated)
    }

    /// JSON coding shared by the tracker's import/export and the Settings
    /// backup section (pretty-printed output so exported files are readable).
    static func exportData(_ records: [ExpenseRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    static func decode(from data: Data) throws -> [ExpenseRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ExpenseRecord].self, from: data)
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
