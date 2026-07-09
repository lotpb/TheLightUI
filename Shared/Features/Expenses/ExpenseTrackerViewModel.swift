//
//  ExpenseTrackerViewModel.swift
//  TheLightUI
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ExpenseTrackerViewModel {
    var selectedFilter: ExpenseFilter = .all
    var sortOrder: ExpenseSortOrder = .date
    var dateRange: ExpenseDateRange = .thisMonth
    var searchText = ""
    var title = ""
    var amountText = ""
    var category: ExpenseCategory = .meals
    var date = Date()
    var notes = ""
    var isReimbursable = false

    @ObservationIgnored private var editingExpense: Expense?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount != nil
    }

    var parsedAmount: Double? {
        let normalizedAmount = amountText.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(normalizedAmount), amount > 0 else { return nil }
        return amount
    }

    func visibleExpenses(from expenses: [Expense]) -> [Expense] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = expenses.filter { expense in
            guard selectedFilter.includes(expense) else { return false }
            guard dateRange.includes(expense.date) else { return false }
            guard !query.isEmpty else { return true }
            return expense.title.localizedCaseInsensitiveContains(query)
                || expense.category.rawValue.localizedCaseInsensitiveContains(query)
                || expense.notes.localizedCaseInsensitiveContains(query)
        }

        switch sortOrder {
        case .date:
            return filtered.sorted { $0.date > $1.date }
        case .name:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    /// Expects the already-filtered list from `visibleExpenses(from:)` so the
    /// filter isn't recomputed for every metric.
    func totalAmount(of visibleExpenses: [Expense]) -> Double {
        visibleExpenses.reduce(0) { $0 + $1.amount }
    }

    /// Expects the already-filtered list from `visibleExpenses(from:)`.
    func reimbursableTotal(of visibleExpenses: [Expense]) -> Double {
        visibleExpenses.filter(\.isReimbursable).reduce(0) { $0 + $1.amount }
    }

    func categoryTotals(for expenses: [Expense]) -> [(category: ExpenseCategory, total: Double)] {
        ExpenseCategory.allCases.compactMap { category in
            let total = expenses
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            return total > 0 ? (category, total) : nil
        }
        .sorted { $0.total > $1.total }
    }

    func startAdding() {
        editingExpense = nil
        title = ""
        amountText = ""
        category = .meals
        date = .now
        notes = ""
        isReimbursable = false
    }

    func startEditing(_ expense: Expense) {
        editingExpense = expense
        title = expense.title
        amountText = expense.amount.formatted(.number.precision(.fractionLength(2)))
        category = expense.category
        date = expense.date
        notes = expense.notes
        isReimbursable = expense.isReimbursable
    }

    func saveExpense(in context: ModelContext) {
        guard let amount = parsedAmount else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editingExpense {
            editingExpense.title = trimmedTitle
            editingExpense.amount = amount
            editingExpense.category = category
            editingExpense.date = date
            editingExpense.notes = trimmedNotes
            editingExpense.isReimbursable = isReimbursable
        } else {
            let expense = Expense(
                title: trimmedTitle,
                amount: amount,
                category: category,
                date: date,
                notes: trimmedNotes,
                isReimbursable: isReimbursable
            )
            context.insert(expense)
        }

        try? context.save()
    }

    func delete(_ expense: Expense, from context: ModelContext) {
        context.delete(expense)
        try? context.save()
    }

    func exportData(for expenses: [Expense]) throws -> Data {
        let records = expenses.map(ExpenseRecord.init)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    /// Inserts decoded expenses, updating any whose id already exists so that
    /// re-importing an export from the same device restores edited values
    /// instead of silently skipping every record.
    /// Returns the number of inserted and updated expenses.
    func importExpenses(from data: Data, into context: ModelContext) throws -> (inserted: Int, updated: Int) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([ExpenseRecord].self, from: data)

        let existingExpenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let expensesByID = Dictionary(existingExpenses.map { ($0.id, $0) }) { first, _ in first }
        var inserted = 0
        var updated = 0
        for record in records {
            if let existing = expensesByID[record.id] {
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

        // Widen the date range if the current one would hide imported records,
        // so a successful import is always visible in the list.
        if inserted + updated > 0, records.contains(where: { !dateRange.includes($0.date) }) {
            dateRange = .allTime
        }

        return (inserted, updated)
    }
}
