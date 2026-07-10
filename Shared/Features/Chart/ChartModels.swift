//
//  ChartModels.swift
//  TheLightUI
//

import Foundation

// MARK: - Chart Item
/// A single category/value pair plotted as one mark in a chart.
struct ChartItem: Identifiable {
    let id = UUID()
    let type: String
    let value: Double

    static let sampleItems: [ChartItem] = [
        ChartItem(type: "Engineering", value: 100),
        ChartItem(type: "Design", value: 35),
        ChartItem(type: "Operations", value: 72),
        ChartItem(type: "Sales", value: 22),
        ChartItem(type: "Mgmt", value: 130)
    ]
}

// MARK: - Customer Sales Aggregation
/// Customer `amount` values summed per calendar month of the sale (creation) date.
struct CustomerSalesMonth: Identifiable {
    var id: Date { month }
    let month: Date
    let total: Int

    /// Short categorical axis label, e.g. "Jul 26".
    var label: String {
        ChartFormatters.monthLabel.string(from: month)
    }

    static func monthlyTotals(from items: [CustomerItem], calendar: Calendar = .current) -> [CustomerSalesMonth] {
        let groupedByMonth = Dictionary(grouping: items) { item in
            calendar.dateInterval(of: .month, for: item.creationDate)?.start ?? item.creationDate
        }
        return groupedByMonth
            .map { month, items in
                CustomerSalesMonth(month: month, total: items.reduce(0) { $0 + $1.amount })
            }
            .sorted { $0.month < $1.month }
    }
}

// MARK: - Formatters
enum ChartFormatters {
    static let monthLabel: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        return formatter
    }()

    static func currency(_ value: Double) -> String {
        CustomerPresentationFormatters.currency.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func currency(_ value: Int) -> String {
        currency(Double(value))
    }
}
