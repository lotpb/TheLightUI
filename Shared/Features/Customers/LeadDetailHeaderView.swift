//
//  LeadDetailHeaderView.swift
//  TheLightUI
//

import SwiftUI

struct LeadDetailHeaderView: View {
    @AppStorage(SettingsUI.activeColorKey) private var activeColor: Int?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var detail: CustomerItem
    @Binding var showFullscreen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            profileRow
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                InitialsAvatarView(firstName: detail.first, lastName: detail.lastname, size: 60)
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                    .shadow(radius: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(CustomerItem.Category.vendor.matches(detail.category) ? detail.first : "\(detail.first) \(detail.lastname)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if CustomerItem.Category.vendor.matches(detail.category) {
                        Text(detail.lastname)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else if !CustomerItem.Category.employee.matches(detail.category) {
                        Text(detail.formattedAmount)
                            .font(horizontalSizeClass == .compact ? .title2.weight(.bold) : .title.weight(.bold))
                            .foregroundStyle(Color.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Text(detail.category.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15).gradient, in: Capsule())

                if detail.isActive {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15).gradient, in: Capsule())
                }

                if !detail.rate.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color.yellow)
                        Text(detail.rate)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15).gradient, in: Capsule())
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 4)
        }
    }

    private var saleSummaryRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
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

            Button {
                showFullscreen.toggle()
            } label: {
                Label("Map", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.9), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleActive() {
        detail.isActive.toggle()
        activeColor = detail.isActive ? 1 : 0
    }
}
