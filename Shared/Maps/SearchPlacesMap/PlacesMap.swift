//
//  Home.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/3/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
import CoreLocation

struct PlacesMap: View {
    @StateObject private var mapData = MapViewModel()
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    private var trimmedSearchText: String {
        mapData.searchTxt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MapViewUI()
                .environmentObject(mapData)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.28), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                headerPanel

                if shouldShowResults {
                    searchResults
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.black.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            bottomStatusBar
        }
        .alert(isPresented: $mapData.permissionDenied) {
            Alert(
                title: Text("Permission Denied"),
                message: Text("Please Enable Permission In App Settings"),
                dismissButton: .default(Text("Go to Settings"), action: openSettings)
            )
        }
        .onChange(of: mapData.searchTxt) { value in
            scheduleSearch(for: value)
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Places")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Search nearby destinations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    mapData.mapView.setUserTrackingMode(.follow, animated: true)
                    isSearchFocused = false
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 38, height: 38)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Center on current location")
            }

            searchBar
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search restaurants, coffee, parks", text: $mapData.searchTxt)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onSubmit {
                    runSearchIfNeeded()
                }

            if !mapData.searchTxt.isEmpty {
                Button {
                    clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .overlay(Capsule().stroke(Color(.separator).opacity(0.12), lineWidth: 1))
    }

    private var searchResults: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(mapData.places) { place in
                    Button {
                        select(place)
                    } label: {
                        PlaceResultRow(place: place)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(maxHeight: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    }

    private var bottomStatusBar: some View {
        HStack(spacing: 10) {
            Label(statusText, systemImage: statusIcon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color(.separator).opacity(0.14), lineWidth: 1))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var statusText: String {
        if trimmedSearchText.isEmpty { return "Search the map" }
        if mapData.places.isEmpty { return "Looking for \"\(trimmedSearchText)\"" }
        return "\(mapData.places.count) results found"
    }

    private var statusIcon: String {
        if trimmedSearchText.isEmpty { return "map" }
        if mapData.places.isEmpty { return "magnifyingglass" }
        return "mappin.and.ellipse"
    }

    private var shouldShowResults: Bool {
        !trimmedSearchText.isEmpty && !mapData.places.isEmpty
    }

    private func scheduleSearch(for value: String) {
        searchTask?.cancel()

        let query = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            mapData.places.removeAll()
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard query == trimmedSearchText else { return }
                mapData.searchQuery()
            }
        }
    }

    private func runSearchIfNeeded() {
        searchTask?.cancel()
        guard !trimmedSearchText.isEmpty else { return }
        mapData.searchQuery()
    }

    private func select(_ place: Place) {
        isSearchFocused = false
        mapData.selectPlace(place: place)
    }

    private func clearSearch() {
        searchTask?.cancel()
        mapData.searchTxt = ""
        mapData.places.removeAll()
        isSearchFocused = false
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

private struct PlaceResultRow: View {
    let place: Place

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(place.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let location = place.subtitle {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview("Places Map") {
    PlacesMap()
        .preferredColorScheme(.dark)
}
