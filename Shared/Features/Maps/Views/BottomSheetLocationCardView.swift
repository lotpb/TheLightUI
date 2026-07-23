//
//  BottomSheetLocationCardView.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetLocationCardView: View {
    let currentAddressText: String
    let speedText: String
    let altitudeText: String
    let mapsURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            Text(currentAddressText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(nil)

            Divider().opacity(0.2)

            HStack(spacing: 16) {
                Label(speedText, systemImage: "gauge.medium")
                Label(altitudeText, systemImage: "arrow.up.and.down.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            Color(.tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.red)
            Text("Current Location")
                .font(.headline)
            Spacer()
            BottomSheetShareButton(
                url: mapsURL,
                accessibilityLabel: "Share your location"
            )
        }
        .padding(.bottom, 2)
    }
}
