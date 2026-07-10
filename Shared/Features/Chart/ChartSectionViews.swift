//
//  ChartSectionViews.swift
//  TheLightUI
//

import SwiftUI
import Charts

// MARK: - Chart Section
/// Titled container giving every chart a consistent header and height.
struct ChartSection<Content: View>: View {
    private let spacing: CGFloat = 12
    private let chartHeight: CGFloat = 220

    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Label(title, systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(color)

            content
                .frame(height: chartHeight)
        }
    }
}

// MARK: - Category Bar Section
/// A bar chart of customer amounts per category with tap-to-select currency annotations.
struct CategoryBarSection: View {
    let title: String
    let color: Color
    let categoryLabel: String
    let items: [ChartItem]
    @Binding var selection: String?

    var body: some View {
        ChartSection(title: title, color: color) {
            Chart(items) { item in
                BarMark(
                    x: .value(categoryLabel, item.type),
                    y: .value("Amount", item.value)
                )
                .foregroundStyle(color.gradient)
                .opacity(selection == nil || selection == item.type ? 1 : 0.35)
                .annotation(position: .top, alignment: .center) {
                    if selection == item.type {
                        Text(ChartFormatters.currency(item.value))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(color)
                    }
                }
            }
            .modifier(BarSelectionModifier(selectedType: $selection))
        }
    }
}

// MARK: - Bar Selection Modifier
/// Adds tap-to-select interactivity on iOS 17+, where `chartXSelection` is available,
/// while leaving the chart untouched on the project's iOS 16 deployment floor.
struct BarSelectionModifier: ViewModifier {
    @Binding var selectedType: String?

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.chartXSelection(value: $selectedType)
        } else {
            content
        }
    }
}
