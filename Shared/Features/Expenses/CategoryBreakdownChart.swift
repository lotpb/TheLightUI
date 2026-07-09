//
//  CategoryBreakdownChart.swift
//  TheLightUI
//

import SwiftUI
import Charts

/// Donut chart of spend per category with tap-to-highlight selection.
struct CategoryBreakdownChart: View {
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
