//
//  ExpenseTrackerView.swift
//  TheLightUI
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct ExpenseTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @StateObject private var viewModel = ExpenseTrackerViewModel()
    @State private var isShowingEditor = false

    private var visibleExpenses: [Expense] {
        viewModel.visibleExpenses(from: expenses)
    }

    var body: some View {
        List {
            summarySection
            filterSection
            expenseSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.startAdding()
                    isShowingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add expense")
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            NavigationStack {
                ExpenseEditorView(viewModel: viewModel) {
                    viewModel.saveExpense(in: modelContext)
                    isShowingEditor = false
                }
            }
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tracked Spend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalAmount(for: expenses), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }

                HStack(spacing: 12) {
                    SummaryMetricView(
                        title: "Entries",
                        value: "\(visibleExpenses.count)",
                        systemImage: "list.bullet.rectangle"
                    )
                    SummaryMetricView(
                        title: "Reimburse",
                        value: viewModel.reimbursableTotal(for: expenses).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(ExpenseFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var expenseSection: some View {
        if visibleExpenses.isEmpty {
            Section {
                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "tray",
                    description: Text("Add an expense to start tracking spend.")
                )
            }
        } else {
            Section("Recent Expenses") {
                ForEach(visibleExpenses) { expense in
                    NavigationLink {
                        ExpenseDetailView(expense: expense)
                    } label: {
                        ExpenseRowView(expense: expense)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.startEditing(expense)
                            isShowingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.delete(expense, from: modelContext)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            if !viewModel.categoryTotals(for: expenses).isEmpty {
                Section("By Category") {
                    ForEach(viewModel.categoryTotals(for: expenses), id: \.category) { item in
                        HStack {
                            Label(item.category.rawValue, systemImage: item.category.systemImage)
                            Spacer()
                            Text(item.total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.orange.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: expense.category.systemImage)
                    .foregroundStyle(.orange)
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

            Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 17.0, *)
private struct ExpenseDetailView: View {
    let expense: Expense

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
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

@available(iOS 17.0, *)
private struct ExpenseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseTrackerViewModel
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

@available(iOS 17.0, *)
private struct SummaryMetricView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

@available(iOS 17.0, *)
enum ExpensePreviewData {
    @MainActor
    static var container: ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Expense.self, configurations: configuration)

        sampleExpenses.forEach { container.mainContext.insert($0) }
        return container
    }

    static var sampleExpenses: [Expense] {
        [
            Expense(title: "Client lunch", amount: 84.32, category: .meals, date: .now.addingTimeInterval(-86400), notes: "Downtown meeting", isReimbursable: true),
            Expense(title: "Design software", amount: 29.99, category: .software, date: .now.addingTimeInterval(-172800), isReimbursable: false),
            Expense(title: "Airport parking", amount: 46.00, category: .travel, date: .now.addingTimeInterval(-259200), isReimbursable: true),
            Expense(title: "Office supplies", amount: 118.47, category: .supplies, date: .now.addingTimeInterval(-432000), isReimbursable: false)
        ]
    }
}

@available(iOS 17.0, *)
#Preview("Expenses") {
    NavigationStack {
        ExpenseTrackerView()
    }
    .modelContainer(ExpensePreviewData.container)
}
