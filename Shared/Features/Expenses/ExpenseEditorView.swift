//
//  ExpenseEditorView.swift
//  TheLightUI
//

import SwiftUI

/// Form for adding a new expense or editing an existing one. The view model
/// holds the draft fields; `onSave` commits them.
struct ExpenseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExpenseTrackerViewModel
    let onSave: () -> Void

    var body: some View {
        Form {
            Section("Expense") {
                TextField("Title", text: $viewModel.title)
                TextField("Amount", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $viewModel.category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                Toggle("Reimbursable", isOn: $viewModel.isReimbursable)
            }

            Section("Notes") {
                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { onSave() }
                    .disabled(!viewModel.canSave)
            }
        }
    }
}
