//
//  ExpenseTrackerView.swift
//  TheLightUI
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExpenseTrackerView: View {
    @AppStorage("color") private var color: Int?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var viewModel = ExpenseTrackerViewModel()
    @State private var isShowingEditor = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument: ExpenseJSONDocument?
    @State private var transferMessage: String?
    @State private var isShowingTransferAlert = false
    @State private var jsonPreview: ExpenseJSONPreview?

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
        .navigationTitle("Expenses")
        .searchable(text: $viewModel.searchText, prompt: "Search expenses")
        .tint(themeColor)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Date Range", selection: $viewModel.dateRange) {
                        ForEach(ExpenseDateRange.allCases) { range in
                            Label(range.rawValue, systemImage: range.systemImage)
                                .tag(range)
                        }
                    }
                    Picker("Sort By", selection: $viewModel.sortOrder) {
                        ForEach(ExpenseSortOrder.allCases) { order in
                            Label(order.rawValue, systemImage: order.systemImage)
                                .tag(order)
                        }
                    }
                    Divider()
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        startExport()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                    .disabled(expenses.isEmpty)
                    Button {
                        showJSONPreview()
                    } label: {
                        Label("View JSON", systemImage: "doc.text.magnifyingglass")
                    }
                    .disabled(expenses.isEmpty)
                } label: {
                    Image(systemName: viewModel.dateRange != .allTime ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
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
        // .data is included because fileExporter on some iOS versions saves the
        // file without a .json extension, which the system then types as generic
        // data and the picker would grey out.
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json, .plainText, .data]) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Expenses.json"
        ) { result in
            if case .failure(let error) = result {
                showTransferMessage("Export failed: \(error.localizedDescription)")
            }
        }
        .alert(transferMessage ?? "", isPresented: $isShowingTransferAlert) {
            Button("OK", role: .cancel) {}
        }
        .sheet(item: $jsonPreview) { preview in
            ExpenseJSONPreviewView(jsonText: preview.text)
        }
    }

    private func showJSONPreview() {
        do {
            let data = try viewModel.exportData(for: expenses)
            jsonPreview = ExpenseJSONPreview(text: String(decoding: data, as: UTF8.self))
        } catch {
            showTransferMessage("Could not generate JSON: \(error.localizedDescription)")
        }
    }

    private func startExport() {
        do {
            exportDocument = ExpenseJSONDocument(data: try viewModel.exportData(for: expenses))
            isExporting = true
        } catch {
            showTransferMessage("Export failed: \(error.localizedDescription)")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            let result = try viewModel.importExpenses(from: data, into: modelContext)
            showTransferMessage(importMessage(for: result))
        } catch {
            showTransferMessage("Import failed: \(error.localizedDescription)")
        }
    }

    private func importMessage(for result: (inserted: Int, updated: Int)) -> String {
        switch result {
        case (0, 0):
            return "All expenses in this file already exist and are up to date."
        case (let inserted, 0):
            return "Imported \(inserted) expense\(inserted == 1 ? "" : "s")."
        case (0, let updated):
            return "Updated \(updated) existing expense\(updated == 1 ? "" : "s")."
        case (let inserted, let updated):
            return "Imported \(inserted) new and updated \(updated) existing expense\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showTransferMessage(_ message: String) {
        transferMessage = message
        isShowingTransferAlert = true
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tracked Spend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalAmount(of: visibleExpenses), format: ExpenseFormat.currency)
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
                        value: viewModel.reimbursableTotal(of: visibleExpenses).formatted(ExpenseFormat.currency),
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

#Preview("Expenses") {
    NavigationStack {
        ExpenseTrackerView()
    }
    .modelContainer(ExpensePreviewData.container)
}
