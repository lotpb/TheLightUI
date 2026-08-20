//
//  ChartSectionViews.swift
//  TheLightUI
//

import SwiftUI

// MARK: - Chart Stat Card
/// One of three KPI boxes in the stat row at the top of the chart page.
struct ChartStatCard: View {
    let label : String
    let value : String
    let sub   : String
    let color : Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(sub)
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Chart Section Card
/// Titled card with a thin colored top accent bar, matching the web's ChartCard component.
struct ChartSectionCard<Content: View>: View {
    let title       : String
    let accentColor : Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                content
            }
            .padding(14)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
