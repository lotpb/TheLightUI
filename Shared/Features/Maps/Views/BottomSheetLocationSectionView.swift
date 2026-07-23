//
//  BottomSheetLocationSectionView.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetLocationSectionView: View {
    let destinationAddressText: String
    let locationRows: [BottomSheetLocationInfoRow]
    let destinationMapsURL: URL?

    var body: some View {
        Group {
            destinationCard
            locationDataHeader
            locationDataGrid
            Spacer(minLength: 8)
        }
    }

    private var destinationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.red)
                Text("Destination Location")
                    .font(.headline)
                Spacer()
                BottomSheetShareButton(
                    url: destinationMapsURL,
                    accessibilityLabel: "Share destination address"
                )
            }

            Text(destinationAddressText)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    private var locationDataHeader: some View {
        Text("Location Data")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private var locationDataGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(locationRows) { row in
                locationRowCell(row)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    private func locationRowCell(_ row: BottomSheetLocationInfoRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.systemImage)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 10) {
                Text(row.title)
                    .font(.callout)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(row.value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white.opacity(0.52), lineWidth: 1)
        }
    }
}
