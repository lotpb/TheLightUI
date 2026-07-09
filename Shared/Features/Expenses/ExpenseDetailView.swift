//
//  ExpenseDetailView.swift
//  TheLightUI
//

import SwiftUI

/// Read-only detail screen for a single expense.
struct ExpenseDetailView: View {
    let expense: Expense

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(expense.amount, format: ExpenseFormat.currency)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Label(expense.category.rawValue, systemImage: expense.category.systemImage)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Details") {
                LabeledContent("Date") { Text(expense.date, style: .date) }
                LabeledContent("Type") { Text(expense.isReimbursable ? "Reimbursable" : "Personal") }
                if !expense.notes.isEmpty {
                    LabeledContent("Notes") { Text(expense.notes) }
                }
            }
        }
        .navigationTitle(expense.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
