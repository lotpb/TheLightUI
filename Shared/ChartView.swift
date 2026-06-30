//
//  ChartView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/10/22.
//

import SwiftUI
import Charts

// MARK: - Chart Model
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

// MARK: - Charts
struct ChartView: View {
    private enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let sectionSpacing: CGFloat = 24
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: String?
    private let items = ChartItem.sampleItems

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
                barChartSection
                lineChartSection
                areaChartSection
            }
            .padding()
        }
    }

    private var selectedItem: ChartItem? {
        guard let selectedType else { return nil }
        return items.first { $0.type == selectedType }
    }

    private var barChartSection: some View {
        ChartSection(title: "Bar", color: .red) {
            Chart(items) { item in
                BarMark(
                    x: .value("Department", item.type),
                    y: .value("Profit", item.value)
                )
                .foregroundStyle(Color.red.gradient)
                .opacity(selectedType == nil || selectedType == item.type ? 1 : 0.35)
                .annotation(position: .top, alignment: .center) {
                    if selectedType == item.type {
                        Text(item.value, format: .number)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .modifier(BarSelectionModifier(selectedType: $selectedType))
        }
    }

    private var lineChartSection: some View {
        ChartSection(title: "Line", color: .blue) {
            Chart(items) { item in
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
            Chart(items) { item in
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

// MARK: - Bar Selection Modifier
/// Adds tap-to-select interactivity on iOS 17+, where `chartXSelection` is available,
/// while leaving the chart untouched on the project's iOS 16 deployment floor.
private struct BarSelectionModifier: ViewModifier {
    @Binding var selectedType: String?

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.chartXSelection(value: $selectedType)
        } else {
            content
        }
    }
}

// MARK: - Chart Section
private struct ChartSection<Content: View>: View {
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

// MARK: - Preview
#Preview("Charts - Dark") {
    ChartView()
        .preferredColorScheme(.dark)
}
