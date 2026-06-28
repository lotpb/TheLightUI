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
    var id = UUID()
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

    private var barChartSection: some View {
        ChartSection(title: "Bar", color: .red) {
            Chart(items) { item in
                BarMark(
                    x: .value("Department", item.type),
                    y: .value("Profit", item.value)
                )
                .foregroundStyle(Color.red.gradient)
            }
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
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle.fill")
            }
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
                .foregroundColor(color)

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
