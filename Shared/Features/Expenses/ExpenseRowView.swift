//
//  ExpenseRowView.swift
//  TheLightUI
//

import SwiftUI

/// List row summarizing a single expense.
struct ExpenseRowView: View {
    let expense: Expense
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: expense.category.systemImage)
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(expense.category.rawValue)
                    Text(expense.date, style: .date)
                    if expense.isReimbursable {
                        Text("Reimbursable")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text(expense.amount, format: ExpenseFormat.currency)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
    }
}
