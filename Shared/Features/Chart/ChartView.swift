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

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChartViewModel
    @State private var selectedJob: String?
    @State private var selectedProduct: String?
    @State private var selectedSalesman: String?
    @State private var selectedContractor: String?
    private let sampleItems = ChartItem.sampleItems

    init(customerService: CustomerServicing = FirebaseCustomerService()) {
        _viewModel = State(initialValue: ChartViewModel(customerService: customerService))
    }

    var body: some View {
        NavigationStack {
            chartContent
                .frame(maxWidth: Layout.maxContentWidth)
                .navigationTitle("Charts")
                .toolbar { toolbarContent }
        }
    }

    private var chartContent: some View {
        ScrollView {
            VStack(spacing: Layout.sectionSpacing) {
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

    private var customerSalesSection: some View {
        ChartSection(
            title: "Customer Sales · \(viewModel.formattedTotalAmount) · \(viewModel.customerCount) Customers",
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle.fill")
            }
        }
    }
}

// MARK: - Preview
#Preview("Charts - Dark") {
    ChartView(customerService: PreviewCustomerService())
        .preferredColorScheme(.dark)
}
