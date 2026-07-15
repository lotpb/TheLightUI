//
//  MapRouteService.swift
//  TheLightUI
//

import CoreLocation
import MapKit

struct MapRouteResult {
    let route: MKRoute
    let destinationCoordinate: CLLocationCoordinate2D
    let directions: [MapRouteStep]
}

enum MapRouteError: LocalizedError {
    case addressNotFound
    case routeNotFound

    var errorDescription: String? {
        switch self {
        case .addressNotFound:
            return "Could not find that address"
        case .routeNotFound:
            return "Could not calculate a route"
        }
    }
}

@MainActor
final class MapRouteService {
    private let geocoder = CLGeocoder()
    private var currentDirections: MKDirections?

    func cancel() {
        geocoder.cancelGeocode()
        currentDirections?.cancel()
        currentDirections = nil
    }

    /// Resolves a destination address to a coordinate without calculating a route.
    func geocode(_ destination: MapDestination) async throws -> CLLocationCoordinate2D {
        let placemarks = try await geocoder.geocodeAddressString(destination.address)
        guard let location = placemarks.first?.location else {
            throw MapRouteError.addressNotFound
        }
        return location.coordinate
    }

    func calculateRoute(
        from sourceCoordinate: CLLocationCoordinate2D,
        to destination: MapDestination
    ) async throws -> MapRouteResult {
        cancel()

        let destinationCoordinate = try await geocode(destination)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        currentDirections = directions

        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw MapRouteError.routeNotFound
        }

        return MapRouteResult(
            route: route,
            destinationCoordinate: destinationCoordinate,
            directions: route.steps.compactMap { step in
                guard !step.instructions.isEmpty else { return nil }

                return MapRouteStep(
                    instructions: step.instructions,
                    distanceText: MapFormat.distance(step.distance),
                    travelTimeText: MapFormat.travelTime(Self.estimatedTravelTime(for: step, in: route))
                )
            }
        )
    }

    private static func estimatedTravelTime(for step: MKRoute.Step, in route: MKRoute) -> TimeInterval {
        guard route.distance > 0 else { return 0 }
        return route.expectedTravelTime * (step.distance / route.distance)
    }
}
