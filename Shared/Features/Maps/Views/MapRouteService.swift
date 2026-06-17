//
//  MapRouteService.swift
//  TheLightUI
//

import CoreLocation
import MapKit

struct MapRouteStep: Identifiable, Hashable {
    let id = UUID()
    let instructions: String
    let distanceText: String
    let travelTimeText: String
}

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

    func calculateRoute(
        from sourceCoordinate: CLLocationCoordinate2D,
        to destination: MapDestination
    ) async throws -> MapRouteResult {
        cancel()

        let placemarks = try await geocoder.geocodeAddressString(destination.address)
        guard let location = placemarks.first?.location else {
            throw MapRouteError.addressNotFound
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        currentDirections = directions

        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw MapRouteError.routeNotFound
        }

        return MapRouteResult(
            route: route,
            destinationCoordinate: location.coordinate,
            directions: route.steps.compactMap { step in
                guard !step.instructions.isEmpty else { return nil }

                return MapRouteStep(
                    instructions: step.instructions,
                    distanceText: Self.formatDistance(step.distance),
                    travelTimeText: Self.formatTravelTime(Self.estimatedTravelTime(for: step, in: route))
                )
            }
        )
    }

    private static func formatTravelTime(_ travelTime: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = travelTime >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: max(travelTime, 60)) ?? "1 min"
    }

    private static func estimatedTravelTime(for step: MKRoute.Step, in route: MKRoute) -> TimeInterval {
        guard route.distance > 0 else { return 0 }
        return route.expectedTravelTime * (step.distance / route.distance)
    }

    private static func formatDistance(_ meters: CLLocationDistance) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = [.providedUnit]

        let measurementSystem = Locale.current.measurementSystem
        let isMetric = (measurementSystem == .metric || measurementSystem == .uk)
        let targetUnit: UnitLength = isMetric ? .kilometers : .miles
        let converted = measurement.converted(to: targetUnit)

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter = numberFormatter

        return formatter.string(from: converted)
    }
}
