//
//  ChartView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/10/22.
//

import SwiftUI
import Charts

// MARK: - Private helpers (file-scope so chart axis closures can capture without self)

private func chartShortK(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "$%.1fM", Double(n) / 1_000_000) }
    if n >= 1_000     { return String(format: "$%.0fk", Double(n) / 1_000) }
    return "$\(n)"
}

// MARK: - ChartView

struct ChartView: View {
    @Environment(\.tabBarOverlap) private var tabBarOverlap
    @State private var viewModel: ChartViewModel

    // No NavigationStack here: this view is pushed onto the main menu's
    // stack, and a nested stack inside a pushed destination is unsupported.
    // Standalone presentations wrap it at the call site.
    init(customerStore: CustomerStore) {
        _viewModel = State(initialValue: ChartViewModel(customerStore: customerStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryTabs
                    .padding(.top, 8)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if !viewModel.hasCustomers {
                    emptyState
                } else {
                    statRow
                    monthlyTrendCard
                    if !viewModel.jobTotals.isEmpty {
                        horizontalBarCard(title: "By Job",        items: viewModel.jobTotals,        color: .purple)
                    }
                    if !viewModel.productTotals.isEmpty {
                        horizontalBarCard(title: "By Product",    items: viewModel.productTotals,    color: .cyan)
                    }
                    if !viewModel.salesmanTotals.isEmpty {
                        horizontalBarCard(title: "By Salesman",   items: viewModel.salesmanTotals,   color: .green)
                    }
                    if !viewModel.contractorTotals.isEmpty {
                        horizontalBarCard(title: "By Contractor", items: viewModel.contractorTotals, color: .orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: tabBarOverlap)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { printChart() } label: {
                    Image(systemName: "printer")
                }
                .disabled(!viewModel.hasCustomers || viewModel.isLoading)
            }
        }
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categoryOptions, id: \.self) { cat in
                    let active = viewModel.categoryFilter == cat
                    Button(cat + "s") {
                        viewModel.categoryFilter = cat
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(active ? Color.indigo : Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(active ? Color.white : Color.secondary)
                    .clipShape(Capsule())
                    .shadow(color: active ? Color.indigo.opacity(0.35) : .clear, radius: 5, y: 3)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("📊")
                .font(.system(size: 40))
            Text("No \(viewModel.categoryFilter.lowercased())s found")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)
            Text("Try selecting a different category")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Stat Row

    private var statRow: some View {
        let activeRate = viewModel.customerCount > 0
            ? Int(round(Double(viewModel.activeCustomerCount) / Double(viewModel.customerCount) * 100)) : 0
        let monthCount = viewModel.monthlySales.count

        return HStack(spacing: 10) {
            ChartStatCard(label: "Total",
                          value: "\(viewModel.customerCount)",
                          sub: "\(viewModel.categoryFilter)s on record",
                          color: .indigo)
            ChartStatCard(label: "Active",
                          value: "\(viewModel.activeCustomerCount)",
                          sub: "\(activeRate)% activation rate",
                          color: .green)
            ChartStatCard(label: "Revenue",
                          value: viewModel.formattedTotalAmount,
                          sub: monthCount > 0 ? "across \(monthCount) months" : "no data yet",
                          color: .orange)
        }
    }

    // MARK: - Monthly Trend

    private var monthlyTrendCard: some View {
        ChartSectionCard(title: "Monthly Revenue Trend", accentColor: .indigo) {
            if viewModel.monthlySales.isEmpty {
                Text("No data")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            } else {
                Chart(viewModel.monthlySales) { entry in
                    AreaMark(
                        x: .value("Month", entry.label),
                        y: .value("Revenue", entry.total)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.45), Color.indigo.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Month", entry.label),
                        y: .value("Revenue", entry.total)
                    )
                    .foregroundStyle(Color.indigo)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks { _ in AxisValueLabel().font(.system(size: 12)) }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(chartShortK(v)).font(.system(size: 12))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    // MARK: - Horizontal Bar Charts

    private func horizontalBarCard(title: String, items: [ChartItem], color: Color) -> some View {
        let top = Array(items.prefix(10))
        let chartHeight = CGFloat(max(2, top.count)) * 44.0

        return ChartSectionCard(title: title, accentColor: color) {
            Chart(top) { item in
                BarMark(
                    x: .value("Amount", item.value),
                    y: .value("Name",   item.type)
                )
                .foregroundStyle(color.gradient)
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(chartShortK(Int(v))).font(.system(size: 12))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in AxisValueLabel().font(.system(size: 12)) }
            }
            .frame(height: chartHeight)
        }
    }

    // MARK: - Print

    private var printableHTML: String {
        func tableSection(title: String, items: [ChartItem]) -> String {
            guard !items.isEmpty else { return "" }
            let rows = items.map {
                "<tr><td>\($0.type)</td><td class=\"amount\">\(ChartFormatters.currency($0.value))</td></tr>"
            }.joined(separator: "\n")
            return """
            <h3>\(title)</h3>
            <table>
              <tr><th>Name</th><th>Amount</th></tr>
              \(rows)
            </table>
            """
        }

        let monthlyRows = viewModel.monthlySales.map {
            "<tr><td>\($0.label)</td><td class=\"amount\">\(ChartFormatters.currency($0.total))</td></tr>"
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
          .header { border-bottom: 2px solid #6366f1; padding-bottom: 14px; margin-bottom: 24px; }
          .title { font-size: 26px; font-weight: 700; color: #6366f1; }
          .subtitle { font-size: 14px; color: #6e6e73; margin-top: 4px; }
          h3 { font-size: 15px; font-weight: 700; color: #3a3a3c; margin: 24px 0 8px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
          th { background: #6366f1; color: #fff; padding: 7px 12px; font-size: 13px; text-align: left; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          td { padding: 7px 12px; font-size: 13px; }
          .amount { text-align: right; font-weight: 600; }
          .footer { margin-top: 32px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style>
        </head>
        <body>
          <div class="header">
            <div class="title">Analytics — \(viewModel.categoryFilter)s</div>
            <div class="subtitle">\(viewModel.customerCount) record\(viewModel.customerCount == 1 ? "" : "s") · Total \(viewModel.formattedTotalAmount)</div>
          </div>
          \(monthlySection)
          \(tableSection(title: "By Job",        items: viewModel.jobTotals))
          \(tableSection(title: "By Product",    items: viewModel.productTotals))
          \(tableSection(title: "By Salesman",   items: viewModel.salesmanTotals))
          \(tableSection(title: "By Contractor", items: viewModel.contractorTotals))
          <div class="footer">Printed from The Light · \(Date().formatted(date: .long, time: .omitted))</div>
        </body>
        </html>
        """
    }

    private func printChart() {
        #if canImport(UIKit)
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = "\(viewModel.categoryFilter) Analytics Report"
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: printableHTML)
        controller.printFormatter = formatter
        controller.present(animated: true)
        #endif
    }
}

// MARK: - Preview

#Preview("Charts - Dark") {
    NavigationStack {
        ChartView(customerStore: CustomerStore(customerService: PreviewCustomerService()))
    }
    .preferredColorScheme(.dark)
}
