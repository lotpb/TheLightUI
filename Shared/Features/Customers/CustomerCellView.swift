//
//  CustomerCellView.swift
//  TheLightUI
//

// Row cell for the customer list: avatar, name/address summary, and amount/date.

import SwiftUI

struct CustomerCellView: View, Equatable {
    // Layout constants for sizes used in the cell.
    fileprivate enum Layout {
        static let avatarSize: CGFloat = 50
        static let actionIconSize: CGFloat = 20
        static let summaryWidth: CGFloat = 90
        static let summaryHeight: CGFloat = 25
        static let textMinimumScaleFactor = 0.5
    }

    // Customer data to render.
    let data: CustomerItem
    // Whether to enable the comments action.
    let showsComments: Bool
    // Persisted theme color choice passed down from the parent list.
    let color: Int?

    // Cell-local theme color convenience.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    // Row layout: avatar, summary, spacer, and amount/date summary.
    var body: some View {
        HStack(alignment: .top) {
            avatar
            customerSummary
            Spacer()
            amountSummary
        }
    }

    // Monogram avatar built from the customer's initials.
    private var avatar: some View {
        InitialsAvatarView(firstName: data.first, lastName: data.lastname, size: Layout.avatarSize)
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .padding(.top, 5)
    }

    // Name, address, and row-level actions.
    private var customerSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.lastname)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .customerCellSingleLineText()
                .padding(.top, 3)
                .accessibilityLabel(Text("Customer name \(data.lastname)"))

            Text(data.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .customerCellSingleLineText()
                .accessibilityLabel(Text("Address \(data.address)"))

            rowActions
        }
        .padding(.leading, 10)
    }

    // Inline action icons (message-like and like).
    private var rowActions: some View {
        HStack(spacing: 20) {
            // Only enabled when there are comments to show.
            Button(action: {}) {
                actionIcon("text.bubble.fill")
            }
            .disabled(!showsComments)

            Button(action: {}) {
                actionIcon("hand.thumbsup.fill")
            }
        }
        .buttonStyle(.plain)
    }

    // Right-aligned date and amount summary.
    private var amountSummary: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(data.formattedCreationDate)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .font(.caption2)
                .foregroundStyle(themeColor)
                .customerCellScaledText()
                .padding(.top, 3)
                .accessibilityLabel(Text("Created on \(data.formattedCreationDate)"))

            Text(data.formattedAmount)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .customerCellSingleLineText()
                .foregroundStyle(.primary)
                .font(.headline)
                .accessibilityLabel(Text("Amount \(data.formattedAmount)"))
        }
    }

    // Helper to render a consistent action icon.
    private func actionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: Layout.actionIconSize, height: Layout.actionIconSize)
            .foregroundStyle(themeColor)
    }
}

private extension View {
    func customerCellScaledText() -> some View {
        minimumScaleFactor(CustomerCellView.Layout.textMinimumScaleFactor)
    }

    func customerCellSingleLineText() -> some View {
        lineLimit(1)
            .customerCellScaledText()
    }
}
