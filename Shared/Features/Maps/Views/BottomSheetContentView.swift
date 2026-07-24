//
//  BottomSheetContentView.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetContentView: View {
    @Binding var selection: Int
    let favorites: [BottomSheetFavorite]
    let currentAddressText: String
    let speedText: String
    let altitudeText: String
    let mapsURL: URL?
    let destinationAddressText: String
    let locationRows: [BottomSheetLocationInfoRow]
    let destinationMapsURL: URL?
    let onSelectionChange: () -> Void
    var onFavoriteRoute: ((MapDestination) -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            picker
            contentScroll
        }
        // Cap the content width and center it on wide iPad layouts; the sheet
        // background still spans the full width.
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    private var picker: some View {
        Picker("", selection: $selection) {
            Text("Overview").tag(0)
            Text("Details").tag(1)
        }
        .pickerStyle(.segmented)
        .onChange(of: selection) { _, _ in
            onSelectionChange()
        }
        .padding(.horizontal)
    }

    private var contentScroll: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 12) {
                if selection == 0 {
                    BottomSheetFavoritesView(favorites: favorites, onFavoriteRoute: onFavoriteRoute)
                    BottomSheetLocationCardView(
                        currentAddressText: currentAddressText,
                        speedText: speedText,
                        altitudeText: altitudeText,
                        mapsURL: mapsURL
                    )
                } else {
                    BottomSheetLocationSectionView(
                        destinationAddressText: destinationAddressText,
                        locationRows: locationRows,
                        destinationMapsURL: destinationMapsURL
                    )
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
            .foregroundStyle(Color.primary)
        }
    }
}
