//
//  LocationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import CoreLocation
import MapKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var mapView = MKMapView()
    @Published var region = MKCoordinateRegion.defaultRegion
    @Published private(set) var mapType: MKMapType = .standard
    @Published private(set) var location: CLLocation?
    @Published private(set) var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentPlacemark: CLPlacemark?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private static let defaultRegionDistance: CLLocationDistance = 10_000

    override init() {
        super.init()
        configureLocationManager()
    }

    func requestLocateInfo() {
        requestLocation()
    }

    func updateMapType() {
        let newType: MKMapType = (mapType == .standard) ? .hybrid : .standard
        mapType = newType
        mapView.mapType = newType
    }

    var statusString: String {
        switch locationStatus {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        @unknown default: return "unknown"
        }
    }

    func reverseGeocode(location: CLLocation?) {
        guard let location else { return }

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error {
                print("Error reverse geocoding location: \(error.localizedDescription)")
            }

            Task { @MainActor in
                self?.currentPlacemark = placemarks?.first
            }
        }
    }

    func focusLocation() {
        guard let location else { return }
        updateRegion(with: location)
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            stopUpdating()
        @unknown default:
            stopUpdating()
        }
    }

    func startUpdating() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            updateAuthorizationStatus(.notDetermined)
        case .denied, .restricted:
            stopUpdating()
        @unknown default:
            stopUpdating()
        }
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func stopFollowingLocation() {
        stopUpdating()
        mapView.userTrackingMode = .none
        region = mapView.region
    }

    private func configureLocationManager() {
        locationStatus = manager.authorizationStatus
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = true
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            stopUpdating()
        @unknown default:
            stopUpdating()
        }
        updateAuthorizationStatus(status)
    }

    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        if locationStatus != status {
            locationStatus = status
        }
    }

    private func makeRegion(for location: CLLocation) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: Self.defaultRegionDistance,
            longitudinalMeters: Self.defaultRegionDistance
        )
    }

    private func updateRegion(with location: CLLocation) {
        let newRegion = makeRegion(for: location)
        region = newRegion
        mapView.setRegion(newRegion, animated: true)
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
    }
}

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        location = latestLocation
        updateRegion(with: latestLocation)
        reverseGeocode(location: latestLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}
