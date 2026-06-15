//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import MapKit

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

struct MapUI: View {
    @StateObject private var manager = LocationManager()
    @StateObject private var userViewModel = MainMessagesViewModel()
    @State private var directions: [String] = []
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
            mapLayer
            MapButtonView(
                manager: manager,
                profileImageURL: userViewModel.chatUser?.profileImageUrl,
                directions: $directions,
                mapType: $mapType
            )
            .zIndex(1)
            routeStatusBanner
                .zIndex(2)
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
            .ignoresSafeArea(.all, edges: .all)
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
            .ignoresSafeArea(.all, edges: .all)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
        .padding(.top, 82)
        .padding(.horizontal)
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

struct MapUI_Previews: PreviewProvider {
    static var previews: some View {
        MapUI(mode: .currentLocation, travelTime: 0.00, distance: 0.00)
            .preferredColorScheme(.dark)
    }
}

