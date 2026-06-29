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
    var currentMonthOnly = false
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
            if currentMonthOnly,
               !Calendar.current.isDate(expense.date, equalTo: .now, toGranularity: .month) {
                return false
            }
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

    func totalAmount(for expenses: [Expense]) -> Double {
        visibleExpenses(from: expenses).reduce(0) { $0 + $1.amount }
    }

    func reimbursableTotal(for expenses: [Expense]) -> Double {
        visibleExpenses(from: expenses).filter(\.isReimbursable).reduce(0) { $0 + $1.amount }
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
}
