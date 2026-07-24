//
//  LeadDetailHeaderView.swift
//  TheLightUI
//

import SwiftUI

struct LeadDetailHeaderView: View {
    @AppStorage("activeColor") private var activeColor: Int?

    @Binding var detail: CustomerItem
    @Binding var showFullscreen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            profileRow
            followMapRow
            Divider()
            saleSummaryRow
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .fullScreenCover(isPresented: $showFullscreen) {
            MapUI(
                mode: .route(
                    destination: MapDestination(
                        street: detail.street,
                        city: detail.city,
                        state: detail.state,
                        zip: detail.zip
                    )
                ),
                travelTime: 0.00,
                distance: 0.00
            )
        }
    }

    private var profileRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(CustomerItem.Category.vendor.matches(detail.category) ? detail.first : detail.lastname)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(detail.street)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                Text(detail.address)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 1)

            VStack(spacing: 8) {
                InitialsAvatarView(firstName: detail.first, lastName: detail.lastname, size: 88)
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                    .shadow(radius: 2)

                Text(detail.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width:25)
            }
        }
    }

    private var followMapRow: some View {
        HStack(alignment: .center, spacing: 12) {
            // A Button (rather than onTapGesture) gives VoiceOver the button trait
            // and standard press feedback.
            Button {
                toggleActive()
            } label: {
                HStack(spacing: 6) {
                    Text(detail.isActive ? "Following" : "Follow")
                        .foregroundStyle(Color.accentColor)
                    Image(systemName: detail.isActive ? "star.fill" : "star")
                        .foregroundStyle(detail.isActive ? Color.yellow : Color.secondary)
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle Follow")

            Spacer()

            Button {
                showFullscreen.toggle()
            } label: {
                Label("Map", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.mini)
        }
    }

    private var saleSummaryRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                let isVendor = CustomerItem.Category.vendor.matches(detail.category)
                let isEmployee = CustomerItem.Category.employee.matches(detail.category)
                Text(isVendor ? detail.lastname : isEmployee ? detail.adNo : detail.formattedAmount)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(isVendor ? CustomerLabels.profession : isEmployee ? CustomerLabels.department : CustomerLabels.saleDate)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(detail.formattedCreationDate)
                    .font(.headline)
            }

            Spacer()

            if detail.rate == "5" {
                Text("Priority")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private func toggleActive() {
        detail.isActive.toggle()
        activeColor = detail.isActive ? 1 : 0
    }
}
