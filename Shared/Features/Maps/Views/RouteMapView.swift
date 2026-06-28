//
//  RouteMapView.swift
//  TheLightUI
//

import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: UIViewRepresentable {
    var manager: LocationManager
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var directions: [MapRouteStep]
    @Binding var routeStatus: RouteStatus
    let mode: MapMode
    @Binding var region: MKCoordinateRegion

    @Binding var mapType: MKMapType
    let onUserInteraction: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onUserInteraction: onUserInteraction)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = context.coordinator.mapView
        mapView.delegate = context.coordinator
        configure(mapView)
        updateRoute(on: mapView, context: context)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.onUserInteraction = onUserInteraction
        context.coordinator.onVisibleRegionChanged = { region = $0 }
        uiView.mapType = mapType
        uiView.userTrackingMode = manager.isFollowingLocation ? .follow : .none

        if context.coordinator.appliedMapType != mapType {
            context.coordinator.appliedMapType = mapType
            updateCameraForMapType(on: uiView)
        }

        updateRegionIfNeeded(on: uiView)
        updateRoute(on: uiView, context: context)
    }

    private func configure(_ mapView: MKMapView) {
        mapView.mapType = mapType
        mapView.pointOfInterestFilter = .init(including: [.evCharger, .gasStation])
        mapView.showsBuildings = true
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.userTrackingMode = manager.isFollowingLocation ? .follow : .none
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true
    }

    private func updateCameraForMapType(on mapView: MKMapView) {
        let center = mapView.centerCoordinate
        let isFlyover = mapType == .hybridFlyover || mapType == .satelliteFlyover
        let camera = MKMapCamera(
            lookingAtCenter: center,
            fromDistance: isFlyover ? 1200 : 2000,
            pitch: isFlyover ? 60 : 0,
            heading: mapView.camera.heading
        )
        mapView.setCamera(camera, animated: true)
        mapView.showsBuildings = isFlyover
    }

    private func updateRegionIfNeeded(on mapView: MKMapView) {
        guard manager.isFollowingLocation else { return }
        guard CLLocationCoordinate2DIsValid(region.center) else { return }

        let currentCenter = mapView.region.center
        let desiredCenter = region.center

        // Compute approximate distance between centers using CoreLocation
        let current = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
        let desired = CLLocation(latitude: desiredCenter.latitude, longitude: desiredCenter.longitude)
        let distanceMeters = current.distance(from: desired)

        // Only update if the center moved more than 50 meters
        guard distanceMeters > 50 else { return }
        mapView.setRegion(region, animated: true)
    }

    private func updateRoute(on mapView: MKMapView, context: Context) {
        guard case .route(let destination) = mode else {
            clearRoute(on: mapView, context: context)
            return
        }
        guard let userLocation = manager.location else {
            routeStatus = .loading
            return
        }

        guard context.coordinator.shouldRecalculateRoute(
            to: destination,
            from: userLocation,
            routeStatus: routeStatus
        ) else { return }

        let routeKey = context.coordinator.routeRequestKey(for: destination, from: userLocation)
        context.coordinator.routeKey = routeKey
        context.coordinator.markRouteRequest(to: destination, from: userLocation)

        context.coordinator.routeTask?.cancel()
        context.coordinator.routeService.cancel()
        routeStatus = .loading

        let endPoint = destination.displayName

        context.coordinator.routeTask = Task { @MainActor in
            do {
                let result = try await context.coordinator.routeService.calculateRoute(
                    from: userLocation.coordinate,
                    to: destination
                )
                guard context.coordinator.routeKey == routeKey else { return }

                let sourcePin = makeAnnotation(
                    coordinate: userLocation.coordinate,
                    title: "Start",
                    subtitle: "Current Location"
                )
                let destPin = makeAnnotation(
                    coordinate: result.destinationCoordinate,
                    title: "Destination",
                    subtitle: endPoint
                )

                routeStatus = .ready
                travelTime = result.route.expectedTravelTime
                distance = result.route.distance

                directions = result.directions

                draw(
                    route: result.route,
                    sourcePin: sourcePin,
                    destPin: destPin,
                    on: mapView,
                    shouldFrameRoute: manager.isFollowingLocation,
                    context: context
                )
            } catch {
                guard context.coordinator.routeKey == routeKey else { return }
                routeStatus = .failed(routeFailureMessage(for: error))
            }
        }
    }

    private func clearRoute(on mapView: MKMapView, context: Context) {
        let routeKey = "currentLocation"
        guard context.coordinator.routeKey != routeKey else { return }
        context.coordinator.routeKey = routeKey
        context.coordinator.lastRouteOrigin = nil
        context.coordinator.lastRouteDestinationAddress = nil
        context.coordinator.routeTask?.cancel()
        context.coordinator.routeTask = nil
        context.coordinator.routeService.cancel()
        directions = []
        routeStatus = .idle
        travelTime = 0
        distance = 0

        // Remove only our overlays and annotations (keep user location)
        if let existingOverlay = context.coordinator.currentRouteOverlay {
            mapView.removeOverlay(existingOverlay)
            context.coordinator.currentRouteOverlay = nil
        }
        let toRemove = context.coordinator.currentAnnotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(toRemove)
        context.coordinator.currentAnnotations = []
    }

    private func routeFailureMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return "Could not calculate a route"
    }

    private func makeAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }

    private func draw(
        route: MKRoute,
        sourcePin: MKPointAnnotation,
        destPin: MKPointAnnotation,
        on mapView: MKMapView,
        shouldFrameRoute: Bool,
        context: Context
    ) {
        // Remove only our previous overlay and annotations (keep user location)
        if let existing = context.coordinator.currentRouteOverlay {
            mapView.removeOverlay(existing)
        }
        let toRemove = context.coordinator.currentAnnotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(toRemove)

        // Add new annotations and overlay
        mapView.addAnnotations([sourcePin, destPin])
        mapView.addOverlay(route.polyline)

        // Track what we added
        context.coordinator.currentAnnotations = [sourcePin, destPin]
        context.coordinator.currentRouteOverlay = route.polyline

        guard shouldFrameRoute else { return }
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25),
            animated: true
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let mapView = MKMapView()
        var routeKey: String?
        let routeService = MapRouteService()
        var routeTask: Task<Void, Never>?
        var appliedMapType: MKMapType?
        var lastRouteOrigin: CLLocation?
        var lastRouteDestinationAddress: String?
        var onUserInteraction: () -> Void
        var onVisibleRegionChanged: (MKCoordinateRegion) -> Void = { _ in }

        var currentRouteOverlay: MKOverlay?
        var currentAnnotations: [MKAnnotation] = []
        private var isUserDrivenRegionChange = false

        private let routeRecalculationDistance: CLLocationDistance = 100

        init(onUserInteraction: @escaping () -> Void) {
            self.onUserInteraction = onUserInteraction
        }

        func shouldRecalculateRoute(
            to destination: MapDestination,
            from userLocation: CLLocation,
            routeStatus: RouteStatus
        ) -> Bool {
            guard lastRouteDestinationAddress == destination.address else { return true }
            guard let lastRouteOrigin else { return true }
            guard routeStatus != .loading else { return false }
            return userLocation.distance(from: lastRouteOrigin) >= routeRecalculationDistance
        }

        func markRouteRequest(to destination: MapDestination, from userLocation: CLLocation) {
            lastRouteDestinationAddress = destination.address
            lastRouteOrigin = userLocation
        }

        func routeRequestKey(for destination: MapDestination, from userLocation: CLLocation) -> String {
            "\(destination.address)-\(userLocation.coordinate.latitude)-\(userLocation.coordinate.longitude)"
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            let userDriven = regionChangeWasUserDriven(mapView)
            isUserDrivenRegionChange = userDriven
            guard userDriven else { return }
            onVisibleRegionChanged(mapView.region)
            onUserInteraction()
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isUserDrivenRegionChange {
                onVisibleRegionChanged(mapView.region)
            }
            isUserDrivenRegionChange = false
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.blue)
            renderer.lineWidth = 6
            renderer.lineCap = .round
            return renderer
        }

        private func regionChangeWasUserDriven(_ mapView: MKMapView) -> Bool {
            mapView.subviews
                .compactMap(\.gestureRecognizers)
                .flatMap { $0 }
                .contains { gestureRecognizer in
                    gestureRecognizer.state == .began || gestureRecognizer.state == .changed
                }
        }

        deinit {
            routeTask?.cancel()
            mapView.delegate = nil
        }
    }
}

