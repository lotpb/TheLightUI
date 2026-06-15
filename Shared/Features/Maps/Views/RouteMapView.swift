//
//  RouteMapView.swift
//  TheLightUI
//

import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: UIViewRepresentable {
    @ObservedObject var manager: LocationManager
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var directions: [String]
    @Binding var mapstreet: String
    @Binding var mapcity: String
    @Binding var mapstate: String
    @Binding var mapzip: String
    @Binding var region: MKCoordinateRegion

    @Binding var mapType: MKMapType

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = manager.mapView
        mapView.delegate = context.coordinator
        configure(mapView)
        updateRoute(on: mapView, context: context)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.mapType = mapType

        if mapType == .hybridFlyover {
            let center = uiView.centerCoordinate
            let camera = MKMapCamera(
                lookingAtCenter: center,
                fromDistance: 1200, // adjust as needed for your region
                pitch: 60,
                heading: uiView.camera.heading
            )
            uiView.setCamera(camera, animated: true)
            uiView.showsBuildings = true
        } else {
            let center = uiView.centerCoordinate
            let camera = MKMapCamera(
                lookingAtCenter: center,
                fromDistance: 2000,
                pitch: 0,
                heading: uiView.camera.heading
            )
            uiView.setCamera(camera, animated: true)
            uiView.showsBuildings = false
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
        mapView.userTrackingMode = .follow
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true
    }

    private func updateRegionIfNeeded(on mapView: MKMapView) {
        guard CLLocationCoordinate2DIsValid(region.center) else { return }
        guard mapView.region.center.latitude != region.center.latitude || mapView.region.center.longitude != region.center.longitude else { return }
        mapView.setRegion(region, animated: true)
    }

    private func updateRoute(on mapView: MKMapView, context: Context) {
        guard let userLocation = manager.location else { return }

        let address = "\(mapstreet) \(mapcity), \(mapstate) \(mapzip)"
        let routeKey = "\(address)-\(userLocation.coordinate.latitude)-\(userLocation.coordinate.longitude)"
        guard context.coordinator.routeKey != routeKey else { return }
        context.coordinator.routeKey = routeKey

        context.coordinator.geocoder.cancelGeocode()
        context.coordinator.currentDirections?.cancel()

        let endPoint = "\(mapstreet), \(mapcity)"

        context.coordinator.geocoder.geocodeAddressString(address) { placemarks, _ in
            guard context.coordinator.routeKey == routeKey else { return }
            guard let location = placemarks?.first?.location else { return }

            DispatchQueue.main.async {
                let sourceCoordinate = MKPlacemark(coordinate: userLocation.coordinate)
                let destinationCoordinate = MKPlacemark(coordinate: location.coordinate)
                let sourcePin = makeAnnotation(coordinate: sourceCoordinate.coordinate, title: "Start", subtitle: "Current Location")
                let destPin = makeAnnotation(coordinate: destinationCoordinate.coordinate, title: "Destination", subtitle: endPoint)
                let request = makeDirectionsRequest(source: sourceCoordinate, destination: destinationCoordinate)

                let mkDirections = MKDirections(request: request)
                context.coordinator.currentDirections = mkDirections

                mkDirections.calculate { response, _ in
                    guard context.coordinator.routeKey == routeKey else { return }
                    guard let route = response?.routes.first else { return }

                    DispatchQueue.main.async {
                        travelTime = route.expectedTravelTime
                        distance = route.distance
                        directions = route.steps.map(\.instructions).filter { !$0.isEmpty }
                        draw(route: route, sourcePin: sourcePin, destPin: destPin, on: mapView)
                    }
                }
            }
        }
    }

    private func makeAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }

    private func makeDirectionsRequest(source: MKPlacemark, destination: MKPlacemark) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        return request
    }

    private func draw(route: MKRoute, sourcePin: MKPointAnnotation, destPin: MKPointAnnotation, on mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.addAnnotations([sourcePin, destPin])
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25),
            animated: true
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var routeKey: String?
        let geocoder = CLGeocoder()
        var currentDirections: MKDirections?

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.blue)
            renderer.lineWidth = 6
            renderer.lineCap = .round
            return renderer
        }
    }
}

