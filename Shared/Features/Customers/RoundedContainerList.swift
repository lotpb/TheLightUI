//
//  RoundedContainerList.swift
//  TheLightUI
//

import SwiftUI

// A reusable list where each row renders as its own rounded card with spacing
// between rows, like Reminders, matching the spaced list style used app-wide.
// Rows are identified by their element's stable id so state and animations survive updates.
struct RoundedContainerList<RowData: Identifiable, RowContent: View>: View {
    let rows: [RowData]
    let rowContent: (RowData) -> RowContent

    init(_ rows: [RowData], @ViewBuilder rowContent: @escaping (RowData) -> RowContent) {
        self.rows = rows
        self.rowContent = rowContent
    }

    var body: some View {
        VStack(spacing: LeadDetailLayout.rowSpacing) {
            ForEach(rows) { data in
                rowContent(data)
                    .padding(.horizontal, LeadDetailLayout.rowHorizontalPadding)
                    .padding(.vertical, LeadDetailLayout.rowVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.2))
                    )
            }
        }
    }
}
