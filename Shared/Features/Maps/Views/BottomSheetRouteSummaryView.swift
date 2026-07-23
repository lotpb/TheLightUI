//
//  BottomSheetRouteSummaryView.swift
//  TheLightUI
//

import SDWebImageSwiftUI
import SwiftUI

struct BottomSheetRouteSummaryView: View {
    let travelTimeText: String
    let distanceText: String
    let profileImageURL: String?

    var body: some View {
        HStack(spacing: 12) {
            tripIcon
            tripLabels
            Spacer()
            profileImage
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .padding(.horizontal)
    }

    private var tripIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.14))
            Image(systemName: "car.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .frame(width: 34, height: 34)
    }

    private var tripLabels: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Trip Summary")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 14) {
                Label(travelTimeText, systemImage: "clock")
                Label(distanceText, systemImage: "map")
            }
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(Color.primary)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
        }
    }

    private var profileImage: some View {
        ProfileAvatarImage(urlString: profileImageURL)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(radius: 2)
    }
}
