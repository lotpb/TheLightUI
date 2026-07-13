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
        } label: {
            Label("Category", systemImage: "line.3.horizontal.decrease.circle")
        }
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
