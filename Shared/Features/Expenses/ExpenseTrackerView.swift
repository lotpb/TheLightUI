//
//  ExpenseTrackerView.swift
//  TheLightUI
//

import SwiftUI
import SwiftData
import Charts

/// Shared currency format style derived from the user's current locale.
private enum ExpenseFormat {
    static var currency: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }
}

struct ExpenseTrackerView: View {
    @AppStorage("color") private var color: Int?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var viewModel = ExpenseTrackerViewModel()
    @State private var isShowingEditor = false

    private var visibleExpenses: [Expense] {
        viewModel.visibleExpenses(from: expenses)
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    var body: some View {
        List {
            summarySection
            filterSection
            expenseSection
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
        }
        .navigationTitle("Expenses")
        .searchable(text: $viewModel.searchText, prompt: "Search expenses")
        .tint(themeColor)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle(isOn: $viewModel.currentMonthOnly) {
                        Label("This Month", systemImage: "calendar")
                    }
                    Picker("Sort By", selection: $viewModel.sortOrder) {
                        ForEach(ExpenseSortOrder.allCases) { order in
                            Label(order.rawValue, systemImage: order.systemImage)
                                .tag(order)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.currentMonthOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter and sort expenses")
            }
            ToolbarItem(placement: .topBarTrailing) {
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
                        Text(viewModel.totalAmount(for: expenses), format: ExpenseFormat.currency)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundStyle(themeColor)
                }

                HStack(spacing: 12) {
                    SummaryMetricView(
                        title: "Entries",
                        value: "\(visibleExpenses.count)",
                        systemImage: "list.bullet.rectangle",
                        accentColor: themeColor
                    )
                    SummaryMetricView(
                        title: "Reimburse",
                        value: viewModel.reimbursableTotal(for: expenses).formatted(ExpenseFormat.currency),
                        systemImage: "arrow.triangle.2.circlepath",
                        accentColor: themeColor
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
                if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "tray",
                        description: Text("Add an expense to start tracking spend.")
                    )
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
        } else {
            Section("Recent Expenses") {
                ForEach(visibleExpenses) { expense in
                    NavigationLink {
                        ExpenseDetailView(expense: expense)
                    } label: {
                        ExpenseRowView(expense: expense, accentColor: themeColor)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.startEditing(expense)
                            isShowingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(themeColor)
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

            let categoryTotals = viewModel.categoryTotals(for: visibleExpenses)
            if !categoryTotals.isEmpty {
                Section("By Category") {
                    CategoryBreakdownChart(categoryTotals: categoryTotals)
                        .frame(height: 220)
                        .padding(.vertical, 4)

                    ForEach(categoryTotals, id: \.category) { item in
                        HStack {
                            Label(item.category.rawValue, systemImage: item.category.systemImage)
                            Spacer()
                            Text(item.total, format: ExpenseFormat.currency)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct CategoryBreakdownChart: View {
    let categoryTotals: [(category: ExpenseCategory, total: Double)]
    @State private var selectedAmount: Double?

    private var total: Double {
        categoryTotals.reduce(0) { $0 + $1.total }
    }

    /// Maps the raw angle selection back to the category whose cumulative
    /// total spans the selected value.
    private var selectedItem: (category: ExpenseCategory, total: Double)? {
        guard let selectedAmount else { return nil }
        var cumulative = 0.0
        for item in categoryTotals {
            cumulative += item.total
            if selectedAmount <= cumulative { return item }
        }
        return nil
    }

    var body: some View {
        Chart(categoryTotals, id: \.category) { item in
            SectorMark(
                angle: .value("Total", item.total),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(by: .value("Category", item.category.rawValue))
            .opacity(selectedItem == nil || selectedItem?.category == item.category ? 1 : 0.35)
        }
        .chartAngleSelection(value: $selectedAmount)
        .chartLegend(position: .bottom, alignment: .center)
        .chartBackground { proxy in
            GeometryReader { geometry in
                if let plotFrame = proxy.plotFrame {
                    let frame = geometry[plotFrame]
                    VStack(spacing: 2) {
                        Text(selectedItem?.category.rawValue ?? "Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selectedItem?.total ?? total, format: ExpenseFormat.currency)
                            .font(.headline.monospacedDigit())
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: frame.width * 0.5)
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .animation(.snappy, value: selectedItem?.category)
    }
}

private struct ExpenseRowView: View {
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

private struct ExpenseDetailView: View {
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

private struct ExpenseEditorView: View {
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

private struct SummaryMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(accentColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

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

#Preview("Expenses") {
    NavigationStack {
        ExpenseTrackerView()
    }
    .modelContainer(ExpensePreviewData.container)
}
