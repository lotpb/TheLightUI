//
//  SwiftUIRouteMapView.swift
//  TheLightUI
//

import CoreLocation
import MapKit
import SwiftUI

@available(iOS 17.0, *)
struct SwiftUIRouteMapView: View {
    var manager: LocationManager
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var directions: [MapRouteStep]
    @Binding var routeStatus: RouteStatus
    let mode: MapMode
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    let onUserInteraction: () -> Void

    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var routeKey: String?
    @State private var lastRouteOrigin: CLLocation?
    @State private var lastRouteDestinationAddress: String?
    @State private var routeService = MapRouteService()

    private let routeRecalculationDistance: CLLocationDistance = 100

    init(
        manager: LocationManager,
        travelTime: Binding<Double>,
        distance: Binding<Double>,
        directions: Binding<[MapRouteStep]>,
        routeStatus: Binding<RouteStatus>,
        mode: MapMode,
        region: Binding<MKCoordinateRegion>,
        mapType: Binding<MKMapType>,
        onUserInteraction: @escaping () -> Void
    ) {
        self.manager = manager
        self._travelTime = travelTime
        self._distance = distance
        self._directions = directions
        self._routeStatus = routeStatus
        self.mode = mode
        self._region = region
        self._mapType = mapType
        self.onUserInteraction = onUserInteraction
        self._cameraPosition = State(initialValue: .region(region.wrappedValue))
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            UserAnnotation()

            if let userCoordinate = manager.location?.coordinate, case .route = mode {
                Marker("Start", systemImage: "location.fill", coordinate: userCoordinate)
                    .tint(.blue)
            }

            if let destinationCoordinate {
                Marker("Destination", systemImage: "mappin", coordinate: destinationCoordinate)
                    .tint(.red)
            }

            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .mapStyle(mapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: region.center.latitude) { _, _ in
            updateCameraFromRegionIfNeeded()
        }
        .onChange(of: region.center.longitude) { _, _ in
            updateCameraFromRegionIfNeeded()
        }
        .onChange(of: mapType) { _, newValue in
            updateCameraForMapType(newValue)
        }
        .onChange(of: manager.isFollowingLocation) { _, isFollowing in
            guard isFollowing else { return }
            updateCameraFromRegion(force: true)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            region = context.region
            if cameraPosition.positionedByUser {
                onUserInteraction()
            }
        }
        .task(id: routeTaskID) {
            await updateRouteIfNeeded()
        }
    }

    private var routeTaskID: String {
        let coordinate = manager.location?.coordinate
        let lat = coordinate?.latitude ?? 0
        let lon = coordinate?.longitude ?? 0

        switch mode {
        case .currentLocation:
            return "currentLocation"
        case .route(let destination):
            return "\(destination.address)-\(lat)-\(lon)"
        }
    }

    private var mapStyle: MapStyle {
        switch mapType {
        case .satellite:
            return .imagery(elevation: .flat)
        case .hybrid, .hybridFlyover, .satelliteFlyover:
            return .hybrid(elevation: mapType == .hybridFlyover || mapType == .satelliteFlyover ? .realistic : .flat)
        default:
            return .standard(elevation: .flat, pointsOfInterest: [.evCharger, .gasStation], showsTraffic: false)
        }
    }

    private func updateCameraFromRegionIfNeeded() {
        updateCameraFromRegion(force: false)
    }

    private func updateCameraFromRegion(force: Bool) {
        guard manager.isFollowingLocation else { return }
        guard CLLocationCoordinate2DIsValid(region.center) else { return }
        guard force || !cameraPosition.positionedByUser else { return }
        cameraPosition = .region(region)
    }

    private func updateCameraForMapType(_ mapType: MKMapType) {
        guard mapType == .hybridFlyover || mapType == .satelliteFlyover else { return }
        let center = region.center
        guard CLLocationCoordinate2DIsValid(center) else { return }
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: center,
                distance: 1200,
                heading: 0,
                pitch: 60
            )
        )
    }

    private func updateRouteIfNeeded() async {
        guard case .route(let destination) = mode else {
            clearRoute()
            return
        }
        guard let userLocation = manager.location else {
            routeStatus = .loading
            return
        }

        guard shouldRecalculateRoute(to: destination, from: userLocation) else { return }

        let key = routeRequestKey(for: destination, from: userLocation)
        routeKey = key
        lastRouteOrigin = userLocation
        lastRouteDestinationAddress = destination.address

        routeService.cancel()
        routeStatus = .loading

        do {
            let result = try await routeService.calculateRoute(
                from: userLocation.coordinate,
                to: destination
            )
            guard routeKey == key else { return }

            routeStatus = .ready
            route = result.route
            destinationCoordinate = result.destinationCoordinate
            travelTime = result.route.expectedTravelTime
            distance = result.route.distance
            directions = result.directions
            if manager.isFollowingLocation {
                cameraPosition = .rect(result.route.polyline.boundingMapRect)
            }
        } catch {
            guard routeKey == key else { return }
            route = nil
            destinationCoordinate = nil
            directions = []
            routeStatus = .failed(routeFailureMessage(for: error))
            travelTime = 0
            distance = 0
        }
    }

    private func shouldRecalculateRoute(to destination: MapDestination, from userLocation: CLLocation) -> Bool {
        guard lastRouteDestinationAddress == destination.address else { return true }
        guard let lastRouteOrigin else { return true }
        guard routeStatus != .loading else { return false }
        return userLocation.distance(from: lastRouteOrigin) >= routeRecalculationDistance
    }

    private func routeRequestKey(for destination: MapDestination, from userLocation: CLLocation) -> String {
        "\(destination.address)-\(userLocation.coordinate.latitude)-\(userLocation.coordinate.longitude)"
    }

    private func routeFailureMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return "Could not calculate a route"
    }

    private func clearRoute() {
        guard routeKey != "currentLocation" else { return }
        routeKey = "currentLocation"
        lastRouteOrigin = nil
        lastRouteDestinationAddress = nil
        routeService.cancel()
        route = nil
        destinationCoordinate = nil
        directions = []
        routeStatus = .idle
        travelTime = 0
        distance = 0
    }
}
