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
        static let actionIconSize: CGFloat = 16
        static let summaryWidth: CGFloat = 90
        static let summaryHeight: CGFloat = 25
        static let textMinimumScaleFactor = 0.5
    }

    // Customer data to render.
    let data: CustomerItem
    // Whether to enable the comments action.
    let showsComments: Bool
    // Whether to show the inline action icons at the bottom of the cell.
    var showsActions: Bool = true
    // Persisted theme color choice passed down from the parent list.
    let color: Int?

    // Cell-local theme color convenience.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    private var fullName: String {
        if CustomerItem.Category.vendor.matches(data.category) {
            return data.first
        }
        return [data.first, data.lastname].filter { !$0.isEmpty }.joined(separator: " ")
    }

    // Row layout: avatar, summary (expands), amount/date summary (fixed).
    var body: some View {
        HStack(alignment: .top) {
            avatar
            customerSummary
            amountSummary
        }
    }

    // Monogram avatar built from the customer's initials.
    private var avatar: some View {
        InitialsAvatarView(firstName: data.first, lastName: data.lastname, size: Layout.avatarSize)
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .padding(.top, 5)
    }

    // Name, address, and row-level actions — expands to fill all space not used by amountSummary.
    private var customerSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fullName)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.textMinimumScaleFactor)
                .padding(.top, 3)
                .accessibilityLabel(Text("Customer name \(fullName)"))

            Text(data.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .customerCellSingleLineText()
                .accessibilityLabel(Text("Address \(data.address)"))

            if showsActions {
                rowActions
            }
        }
        .padding(.leading, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let isLead = CustomerItem.Category.lead.matches(data.category)
        let amountText = CustomerItem.Category.vendor.matches(data.category)
            ? data.lastname
            : CustomerItem.Category.employee.matches(data.category)
                ? data.adNo
                : isLead
                    ? (data.leadStatus.isEmpty ? "" : data.leadStatus)
                    : data.formattedAmount
        let followUpText = isLead
            ? data.followUpDate.map { CustomerPresentationFormatters.mediumDate.string(from: $0) } ?? ""
            : ""

        return VStack(alignment: .trailing, spacing: 6) {
            Text(data.formattedCreationDate)
                .font(.caption2)
                .foregroundStyle(themeColor)
                .lineLimit(1)
                .minimumScaleFactor(Layout.textMinimumScaleFactor)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .padding(.top, 3)
                .accessibilityLabel(Text("Created on \(data.formattedCreationDate)"))

            if CustomerItem.Category.vendor.matches(data.category), !data.profession.isEmpty {
                Text(data.profession)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.textMinimumScaleFactor)
                    .frame(width: Layout.summaryWidth)
                    .accessibilityLabel(Text("Profession \(data.profession)"))
            }

            Text(amountText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.textMinimumScaleFactor)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .accessibilityLabel(Text(CustomerItem.Category.vendor.matches(data.category) ? "Profession \(data.lastname)" : CustomerItem.Category.employee.matches(data.category) ? "Department \(data.adNo)" : isLead ? "Lead Status \(data.leadStatus)" : "Amount \(data.formattedAmount)"))

            if isLead, !followUpText.isEmpty {
                Text(followUpText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.textMinimumScaleFactor)
                    .frame(width: Layout.summaryWidth)
                    .accessibilityLabel(Text("Follow up \(followUpText)"))
            }
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
