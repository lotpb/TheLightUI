//
//  ChartView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/10/22.
//

import SwiftUI
import Charts

// MARK: - Charts
struct ChartView: View {
    private enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let sectionSpacing: CGFloat = 24
    }

    @Environment(\.tabBarOverlap) private var tabBarOverlap
    @State private var viewModel: ChartViewModel
    @State private var selectedJob: String?
    @State private var selectedProduct: String?
    @State private var selectedSalesman: String?
    @State private var selectedContractor: String?
    private let sampleItems = ChartItem.sampleItems

    init(customerService: CustomerServicing = FirebaseCustomerService()) {
        _viewModel = State(initialValue: ChartViewModel(customerService: customerService))
    }

    // No NavigationStack here: this view is pushed onto the main menu's
    // stack, and a nested stack inside a pushed destination is unsupported.
    // Standalone presentations (fullscreen cover, previews) wrap it in a
    // NavigationStack at the call site.
    var body: some View {
        chartContent
            .frame(maxWidth: Layout.maxContentWidth)
            .navigationTitle("Charts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    categoryFilterMenu
                }
            }
    }

    private var categoryFilterMenu: some View {
        Menu {
            Picker("Category", selection: $viewModel.categoryFilter) {
                ForEach(viewModel.categoryOptions, id: \.self) { option in
                    Text(option)
                }
            }
            Divider()
            Button {
                printChart()
            } label: {
                Label("Print", systemImage: "printer")
            }
            .disabled(!viewModel.hasCustomers)
        } label: {
            Label("Category", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var printableHTML: String {
        func tableSection(title: String, items: [ChartItem]) -> String {
            guard !items.isEmpty else { return "" }
            let rows = items.map { item in
                "<tr><td>\(item.type)</td><td class=\"amount\">\(ChartFormatters.currency(item.value))</td></tr>"
            }.joined(separator: "\n")
            return """
            <h3>\(title)</h3>
            <table>
              <tr><th>Name</th><th>Amount</th></tr>
              \(rows)
            </table>
            """
        }

        let monthlyRows = viewModel.monthlySales.map { entry in
            "<tr><td>\(entry.label)</td><td class=\"amount\">\(ChartFormatters.currency(entry.total))</td></tr>"
        }.joined(separator: "\n")

        let monthlySection = viewModel.monthlySales.isEmpty ? "" : """
        <h3>\(viewModel.categoryFilter) Sales by Month</h3>
        <table>
          <tr><th>Month</th><th>Amount</th></tr>
          \(monthlyRows)
        </table>
        """

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; margin: 40px; color: #1c1c1e; }
          .header { border-bottom: 2px solid #ff9500; padding-bottom: 14px; margin-bottom: 24px; }
          .title { font-size: 26px; font-weight: 700; color: #ff9500; }
          .subtitle { font-size: 14px; color: #6e6e73; margin-top: 4px; }
          h3 { font-size: 15px; font-weight: 700; color: #3a3a3c; margin: 24px 0 8px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
          th { background: #ff9500; color: #fff; padding: 7px 12px; font-size: 13px; text-align: left; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          td { padding: 7px 12px; font-size: 13px; }
          .amount { text-align: right; font-weight: 600; }
          .footer { margin-top: 32px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style>
        </head>
        <body>
          <div class="header">
            <div class="title">Sales Report — \(viewModel.categoryFilter)s</div>
            <div class="subtitle">\(viewModel.customerCount) record\(viewModel.customerCount == 1 ? "" : "s") &bull; Total \(viewModel.formattedTotalAmount)</div>
          </div>
          \(monthlySection)
          \(tableSection(title: "By Job", items: viewModel.jobTotals))
          \(tableSection(title: "By Product", items: viewModel.productTotals))
          \(tableSection(title: "By Salesman", items: viewModel.salesmanTotals))
          \(tableSection(title: "By Contractor", items: viewModel.contractorTotals))
          <div class="footer">Printed from The Light &bull; \(Date().formatted(date: .long, time: .omitted))</div>
        </body>
        </html>
        """
    }

    private func printChart() {
        #if canImport(UIKit)
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = "\(viewModel.categoryFilter) Sales Report"
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: printableHTML)
        controller.printFormatter = formatter
        controller.present(animated: true)
        #endif
    }

    private var chartContent: some View {
        ScrollView {
            VStack(spacing: Layout.sectionSpacing) {
                salesSummaryCell
                customerSalesSection
                jobChartSection
                productChartSection
                salesmanChartSection
                contractorChartSection
                lineChartSection
                areaChartSection
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: tabBarOverlap)
        }
    }

    private var salesSummaryCell: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sales")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.formattedTotalAmount)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.categoryFilter)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.customerCount)")
                    .font(.title3.weight(.semibold))
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var customerSalesSection: some View {
        ChartSection(
            title: "\(viewModel.categoryFilter) Sales",
            color: .orange
        ) {
            // Categorical month labels give evenly spaced, full-width bars;
            // a Date x-axis would scatter thin bars across the whole timeline.
            Chart(viewModel.monthlySales) { entry in
                BarMark(
                    x: .value("Month", entry.label),
                    y: .value("Amount", entry.total)
                )
                .foregroundStyle(Color.orange.gradient)
            }
            .chartXScale(domain: viewModel.monthlySales.map(\.label))
            .overlay {
                if !viewModel.hasCustomers {
                    Text(viewModel.isLoading ? "Loading customers…" : "No customer data")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var jobChartSection: some View {
        CategoryBarSection(title: "Sales by Job", color: .red, categoryLabel: "Job",
                           items: viewModel.jobTotals, selection: $selectedJob)
    }

    private var productChartSection: some View {
        CategoryBarSection(title: "Sales by Product", color: .purple, categoryLabel: "Product",
                           items: viewModel.productTotals, selection: $selectedProduct)
    }

    private var salesmanChartSection: some View {
        CategoryBarSection(title: "Sales by Salesman", color: .teal, categoryLabel: "Salesman",
                           items: viewModel.salesmanTotals, selection: $selectedSalesman)
    }

    private var contractorChartSection: some View {
        CategoryBarSection(title: "Sales by Contractor", color: .indigo, categoryLabel: "Contractor",
                           items: viewModel.contractorTotals, selection: $selectedContractor)
    }

    private var lineChartSection: some View {
        ChartSection(title: "Line", color: .blue) {
            Chart(sampleItems) { item in
                LineMark(
                    x: .value("Department", item.type),
                    y: .value("Profit", item.value)
                )
                .foregroundStyle(Color.blue.gradient)
                .interpolationMethod(.catmullRom)
                .symbol(.circle)
            }
        }
    }

    private var areaChartSection: some View {
        ChartSection(title: "Area", color: .green) {
            Chart(sampleItems) { item in
                AreaMark(
                    x: .value("Department", item.type),
                    y: .value("Profit", item.value)
                )
                .foregroundStyle(Color.green.gradient)
                .interpolationMethod(.catmullRom)
            }
        }
    }
}

// MARK: - Preview
#Preview("Charts - Dark") {
    NavigationStack {
        ChartView(customerService: PreviewCustomerService())
    }
    .preferredColorScheme(.dark)
}
