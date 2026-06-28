//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import MapKit

// Layout & styling constants
private enum MapLayout {
    static let bannerTopPadding: CGFloat = 82
    static let bannerHorizontalPadding: CGFloat = 16
    static let bannerHorizontalContentPadding: CGFloat = 14
    static let bannerVerticalContentPadding: CGFloat = 10
    static let bannerStrokeOpacity: CGFloat = 0.06
}

struct MapDestination: Equatable {
    let street: String
    let city: String
    let state: String
    let zip: String

    var address: String {
        "\(street) \(city), \(state) \(zip)"
    }

    var displayName: String {
        "\(street), \(city)"
    }
}

enum MapMode: Equatable {
    case currentLocation
    case route(destination: MapDestination)
}

enum RouteStatus: Equatable {
    case idle
    case loading
    case ready
    case failed(String)
}

@MainActor
struct MapUI: View {
    @State private var manager = LocationManager()
    @State private var userViewModel = MainMessagesViewModel()
    @State private var directions: [MapRouteStep] = []
    @State private var mapType: MKMapType = .standard
    @State private var routeStatus: RouteStatus = .idle

    private let mode: MapMode

    @State var travelTime: Double
    @State var distance: Double

    init(
        mode: MapMode = .currentLocation,
        travelTime: Double,
        distance: Double
    ) {
        self.mode = mode
        self._travelTime = State(initialValue: travelTime)
        self._distance = State(initialValue: distance)
    }

    init(
        mapstreet: String,
        mapcity: String,
        mapstate: String,
        mapzip: String,
        travelTime: Double,
        distance: Double
    ) {
        self.init(
            mode: .route(
                destination: MapDestination(
                    street: mapstreet,
                    city: mapcity,
                    state: mapstate,
                    zip: mapzip
                )
            ),
            travelTime: travelTime,
            distance: distance
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Base map
            mapLayer
            // Map controls
            MapButtonView(
                manager: manager,
                profileImageURL: userViewModel.chatUser?.profileImageUrl,
                directions: $directions,
                travelTime: $travelTime,
                distance: $distance,
                mapType: $mapType
            )
            .zIndex(1)
            // Route status banner
            routeStatusBanner
                .zIndex(2)
            // Bottom sheet with travel details
            bottomSheetLayer
                .zIndex(3)
        }
        .onAppear {
            manager.startUpdating()
        }
        .onDisappear {
            manager.stopUpdating()
        }
        .task {
            await userViewModel.fetchCurrentUser()
        }
    }

    @ViewBuilder
    private var mapLayer: some View {
        if #available(iOS 17.0, *) {
            makeRouteMapView(usingSwiftUIMap: true)
                .ignoresSafeArea(.all, edges: .all)
        } else {
            makeRouteMapView(usingSwiftUIMap: false)
                .ignoresSafeArea(.all, edges: .all)
        }
    }

    // Builds either SwiftUIRouteMapView (iOS 17+) or RouteMapView with the same parameters.
    @ViewBuilder
    private func makeRouteMapView(usingSwiftUIMap: Bool) -> some View {
        if usingSwiftUIMap {
            if #available(iOS 17.0, *) {
                SwiftUIRouteMapView(
                    manager: manager,
                    travelTime: $travelTime,
                    distance: $distance,
                    directions: $directions,
                    routeStatus: $routeStatus,
                    mode: mode,
                    region: $manager.region,
                    mapType: $mapType,
                    onUserInteraction: manager.pauseFollowingLocation
                )
            } else {
                RouteMapView(
                    manager: manager,
                    travelTime: $travelTime,
                    distance: $distance,
                    directions: $directions,
                    routeStatus: $routeStatus,
                    mode: mode,
                    region: $manager.region,
                    mapType: $mapType,
                    onUserInteraction: manager.pauseFollowingLocation
                )
            }
        } else {
            RouteMapView(
                manager: manager,
                travelTime: $travelTime,
                distance: $distance,
                directions: $directions,
                routeStatus: $routeStatus,
                mode: mode,
                region: $manager.region,
                mapType: $mapType,
                onUserInteraction: manager.pauseFollowingLocation
            )
        }
    }

    @ViewBuilder
    private var routeStatusBanner: some View {
        switch routeStatus {
        case .loading:
            routeStatusContent(systemImage: nil, message: "Calculating route")
        case .failed(let message):
            routeStatusContent(systemImage: "exclamationmark.triangle.fill", message: message)
        case .idle, .ready:
            EmptyView()
        }
    }

    private func routeStatusContent(systemImage: String?, message: String) -> some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.orange)
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, MapLayout.bannerHorizontalContentPadding)
        .padding(.vertical, MapLayout.bannerVerticalContentPadding)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(MapLayout.bannerStrokeOpacity), lineWidth: 1))
        .padding(.top, MapLayout.bannerTopPadding)
        .padding(.horizontal, MapLayout.bannerHorizontalPadding)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: routeStatus)
    }

    private var bottomSheetLayer: some View {
        BottomSheetUI(
            locationManager: manager,
            profileImageURL: userViewModel.chatUser?.profileImageUrl,
            travelTime: $travelTime,
            distance: $distance
        )
    }
}

#Preview("Customers - Dark") {
    MapUI(mode: .currentLocation, travelTime: 0.00, distance: 0.00)
        .preferredColorScheme(.dark)
}


