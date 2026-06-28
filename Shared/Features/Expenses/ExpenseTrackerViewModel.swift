//
//  ExpenseTrackerViewModel.swift
//  TheLightUI
//

import Foundation
import SwiftData

@MainActor
final class ExpenseTrackerViewModel: ObservableObject {
    @Published var selectedFilter: ExpenseFilter = .all
    @Published var title = ""
    @Published var amountText = ""
    @Published var category: ExpenseCategory = .meals
    @Published var date = Date()
    @Published var notes = ""
    @Published var isReimbursable = false

    private var editingExpense: Expense?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount != nil
    }

    var parsedAmount: Double? {
        let normalizedAmount = amountText.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(normalizedAmount), amount > 0 else { return nil }
        return amount
    }

    func visibleExpenses(from expenses: [Expense]) -> [Expense] {
        expenses.filter { selectedFilter.includes($0) }
    }

    func totalAmount(for expenses: [Expense]) -> Double {
        visibleExpenses(from: expenses).reduce(0) { $0 + $1.amount }
    }

    func reimbursableTotal(for expenses: [Expense]) -> Double {
        expenses.filter(\.isReimbursable).reduce(0) { $0 + $1.amount }
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
