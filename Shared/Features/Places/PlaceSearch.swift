//
//  PlaceSearch.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI
import MapKit


enum DisplayType {
    case list, map
}

struct PlaceSearch: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: PlaceListViewModel
    @State private var locationManager = LocationManager()
    
    @State private var searchText: String = ""
    @State private var displayType: DisplayType = .map
    @State private var cameraPosition: MapCameraPosition = .region(.defaultRegion)
    @State private var isDragged: Bool = false
    @State private var isAwaitingRecenter: Bool = false
    @State private var selectedLandmarkID: UUID?
    @State private var travelTime: String?
    @State private var travelDistance: String?
    @State private var isProgrammaticSearchUpdate = false
    let index: Int

    private var numberedLandMarks: [NumberedLandMark] {
        viewModel.landMarks.enumerated().map { itemIndex, landMark in
            NumberedLandMark(landMark: landMark, number: itemIndex + 1)
        }
    }

    @MainActor
    init(
        index: Int,
        viewModel: PlaceListViewModel? = nil
    ) {
        self.index = index
        _viewModel = State(
            initialValue: viewModel ?? PlaceListViewModel(
                placeSearchService: MKLocalPlaceSearchService()
            )
        )
    }
    
    /// Switches to the map, highlights the tapped landmark, and frames the camera so
    /// both the selected pin and the user's current location stay in view.
    private func centerMap(on landMark: LandMark) {
        selectedLandmarkID = landMark.id
        // Show the selected place's name in the search bar without kicking off a new search.
        isProgrammaticSearchUpdate = true
        searchText = landMark.name

        // Frame both the selected pin and the user's location (if known).
        var coordinates = [landMark.coordinate]
        if let userCoordinate = locationManager.location?.coordinate {
            coordinates.append(userCoordinate)
        }
        let region = regionThatFits(coordinates) ?? MKCoordinateRegion(
            center: landMark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        withAnimation(.easeInOut) {
            cameraPosition = .region(region)
        }
        locationManager.stopUpdating()
        isDragged = false
        displayType = .map
        calculateTravelTime(to: landMark)
    }

    /// Estimates driving time from the user's current location to the selected landmark.
    private func calculateTravelTime(to landMark: LandMark) {
        travelTime = nil
        travelDistance = nil
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: landMark.placemark)
        request.transportType = .automobile

        Task {
            let response = try? await MKDirections(request: request).calculateETA()
            guard let response, landMark.id == selectedLandmarkID else { return }

            let timeFormatter = DateComponentsFormatter()
            timeFormatter.allowedUnits = [.hour, .minute]
            timeFormatter.unitsStyle = .abbreviated
            travelTime = timeFormatter.string(from: response.expectedTravelTime)

            let distanceFormatter = MKDistanceFormatter()
            distanceFormatter.unitStyle = .abbreviated
            travelDistance = distanceFormatter.string(fromDistance: response.distance)
        }
    }

    /// Builds a region large enough to enclose every landmark, so all pins are visible at once.
    private func regionThatFits(_ landMarks: [LandMark]) -> MKCoordinateRegion? {
        regionThatFits(landMarks.map(\.coordinate))
    }

    /// Builds a region large enough to enclose all of the given coordinates.
    private func regionThatFits(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard
            let minLat = coordinates.map(\.latitude).min(),
            let maxLat = coordinates.map(\.latitude).max(),
            let minLon = coordinates.map(\.longitude).min(),
            let maxLon = coordinates.map(\.longitude).max()
        else { return nil }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.02)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                PlaceSearchBackground()

                VStack(alignment: .leading, spacing: 14) {
                    header
                    LandMarkCategoryView { selectedCategory in
                        viewModel.searchLandmarks(selectedCategory)
                    }

                    displayPicker
                    resultSummary
                    contentView
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .onAppear {
                // Request permission and a fresh fix so the blue user-location dot
                // appears and the map centers on the user on first launch.
                isAwaitingRecenter = true
                locationManager.requestLocation()
            }
            .onDisappear {
                locationManager.stopUpdating()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search places")
            .onChange(of: searchText) {
                guard !isProgrammaticSearchUpdate else {
                    isProgrammaticSearchUpdate = false
                    return
                }
                viewModel.searchLandmarks(searchText)
            }
            // Frame every result on the map whenever a new set of landmarks loads.
            .onChange(of: viewModel.landMarks.map(\.id)) {
                selectedLandmarkID = nil
                travelTime = nil
                travelDistance = nil
                if let region = regionThatFits(viewModel.landMarks) {
                    cameraPosition = .region(region)
                    isDragged = false
                }
            }
            // Recenter once a fresh location arrives after the user taps Re-center.
            .onChange(of: locationManager.location?.timestamp) {
                guard isAwaitingRecenter, let coordinate = locationManager.location?.coordinate else { return }
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
                isAwaitingRecenter = false
            }
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Search Places")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 4)
    }

    private var displayPicker: some View {
        Picker("Display", selection: $displayType) {
            Label("Map", systemImage: "map.fill").tag(DisplayType.map)
            Label("List", systemImage: "list.bullet").tag(DisplayType.list)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 700)
    }

    private var resultSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: displayType == .map ? "mappin.and.ellipse" : "building.2")
                .foregroundStyle(.blue)

            Text("\(viewModel.landMarks.count) places nearby")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if let travelTime {
                Label(
                    [travelDistance, travelTime].compactMap { $0 }.joined(separator: " · "),
                    systemImage: "car.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var contentView: some View {
        switch displayType {
        case .list:
            LandMarkListView(landMarks: viewModel.landMarks, index: index, onSelect: centerMap)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        case .map:
            mapView
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Once a place is searched/selected, tint the user-location marker the same
            // yellow as the selected pin; otherwise show the default blue location dot.
            if selectedLandmarkID != nil {
                UserAnnotation {
                    Image(systemName: "location.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.yellow, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                }
            } else {
                UserAnnotation()
            }

            ForEach(numberedLandMarks) { item in
                Annotation("", coordinate: item.landMark.coordinate) {
                    MapAnnotationView(
                        number: item.number,
                        isSelected: item.landMark.id == selectedLandmarkID
                    )
                    .scaleEffect(0.7)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 12)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    isDragged = true
                    locationManager.stopUpdating()
                }
        )
        .overlay(alignment: .bottom) {
            if isDragged {
                RecenterButton {
                    isAwaitingRecenter = true
                    locationManager.requestLocation()
                    isDragged = false
                }
                .padding(.bottom, 18)
            }
        }
    }
}

private struct NumberedLandMark: Identifiable {
    let landMark: LandMark
    let number: Int

    var id: UUID {
        landMark.id
    }
}

private struct PlaceSearchBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview("Place Search") {
    PlaceSearch(index: 1)
}

