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

            VStack(spacing: 8) {
                searchBar

                if shouldShowResults {
                    searchResults
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
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

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search", text: $mapData.searchTxt)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .colorScheme(.light)
                .onSubmit {
                    runSearchIfNeeded()
                }

            if !mapData.searchTxt.isEmpty {
                Button {
                    clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private var searchResults: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(mapData.places) { place in
                    Button {
                        select(place)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.black)

                            if let location = place.subtitle {
                                Text(location)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                    }

                    Divider()
                }
            }
        }
        .frame(maxHeight: 260)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
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

#Preview("Places Map") {
    PlacesMap()
        .preferredColorScheme(.dark)
}
