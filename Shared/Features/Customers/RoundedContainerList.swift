//
//  RoundedContainerList.swift
//  TheLightUI
//

import SwiftUI

// A reusable grouped list where all rows share a single rounded card background,
// separated by inset dividers — matching the standard iOS grouped list style.
struct RoundedContainerList<RowData: Identifiable, RowContent: View>: View {
    let rows: [RowData]
    let rowContent: (RowData) -> RowContent

    init(_ rows: [RowData], @ViewBuilder rowContent: @escaping (RowData) -> RowContent) {
        self.rows = rows
        self.rowContent = rowContent
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, data in
                VStack(spacing: 0) {
                    rowContent(data)
                        .padding(.horizontal, LeadDetailLayout.rowHorizontalPadding)
                        .padding(.vertical, LeadDetailLayout.rowVerticalPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if index < rows.count - 1 {
                        Divider()
                            .padding(.leading, LeadDetailLayout.rowHorizontalPadding)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
    }
}
