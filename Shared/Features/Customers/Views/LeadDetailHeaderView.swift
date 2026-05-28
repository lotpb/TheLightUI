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
                mapstreet: detail.street,
                mapcity: detail.city,
                mapstate: detail.state,
                mapzip: detail.zip,
                travelTime: 0.00,
                distance: 0.00
            )
        }
    }

    private var profileRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(detail.lastname)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(detail.street)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(detail.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                Image("taylor_swift_profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                    .shadow(radius: 2)

                Text(detail.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var followMapRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Label(detail.isActive ? "Following" : "Follow", systemImage: detail.isActive ? "star.fill" : "star")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(detail.isActive ? .blue : .secondary)
                .onTapGesture { toggleActive() }
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
                Text(detail.formattedAmount)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(CustomerLabels.saleDate)
                    .font(.caption)
                    .foregroundStyle(.white)
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
                    .foregroundColor(.white)
            }
        }
    }

    private func toggleActive() {
        detail.isActive.toggle()
        activeColor = detail.isActive ? 1 : 0
    }
}
