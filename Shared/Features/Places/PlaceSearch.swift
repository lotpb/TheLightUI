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
    
    private func centerMap(on landMark: LandMark) {
        let region = MKCoordinateRegion(
            center: landMark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        cameraPosition = .region(region)
        locationManager.stopUpdating()
        isDragged = false
        displayType = .map
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
                locationManager.stopUpdating()
            }
            .onDisappear {
                locationManager.stopUpdating()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search places")
            .onChange(of: searchText) {
                viewModel.searchLandmarks(searchText)
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
            UserAnnotation()

            ForEach(numberedLandMarks) { item in
                Annotation("", coordinate: item.landMark.coordinate) {
                    MapAnnotationView(number: item.number)
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

