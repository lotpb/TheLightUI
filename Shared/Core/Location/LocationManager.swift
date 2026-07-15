//
//  LocationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import CoreLocation
import MapKit
import Observation

/// A modern, Swift-concurrency-friendly location manager for MapKit.
/// - Publishes region updates for map camera.
/// - Tracks authorization status and current placemark.
/// - Provides follow/pause controls to conserve power.
@MainActor
@Observable
final class LocationManager: NSObject {
    /// The visible region used by Map views.
    var region = MKCoordinateRegion.defaultRegion
    /// The most recently reported location from Core Location.
    private(set) var location: CLLocation?
    /// The current authorization status.
    private(set) var locationStatus: CLAuthorizationStatus = .notDetermined
    /// The reverse-geocoded placemark for the latest location.
    private(set) var currentPlacemark: CLPlacemark?
    /// The most recent Core Location failure, cleared on the next successful fix.
    private(set) var lastLocationError: Error?
    /// Whether the map should follow the user's location.
    private(set) var isFollowingLocation = true

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let geocoder = CLGeocoder()
    private static let defaultRegionDistance: CLLocationDistance = 10_000

    override init() {
        super.init()
        configureLocationManager()
    }

    func reverseGeocode(location: CLLocation?) {
        guard let location else { return }
        geocoder.cancelGeocode()
        Task { @MainActor in
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                self.currentPlacemark = placemarks.first
            } catch is CancellationError {
                // Ignored: a newer geocode request superseded this one
            } catch {
                print("Error reverse geocoding location: \(error.localizedDescription)")
            }
        }
    }

    /// Centers the map on the latest known location and resumes following.
    func focusLocation() {
        isFollowingLocation = true
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
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            stopUpdating()
        @unknown default:
            stopUpdating()
        }
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Temporarily stops following the user's location to conserve power.
    func pauseFollowingLocation() {
        isFollowingLocation = false
        stopUpdating()
    }

    /// Centers the map on the latest known location and resumes following.
    func resumeFollowingLocation() {
        isFollowingLocation = true
        focusLocation()
        startUpdating()
    }

    private func configureLocationManager() {
        locationStatus = manager.authorizationStatus
        manager.delegate = self
        manager.activityType = .otherNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = true
        manager.allowsBackgroundLocationUpdates = false
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
    }
}

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        // Discard invalid readings. A stale (cached) fix is accepted only when
        // we have none yet — Macs often report just a cached location, which
        // would otherwise leave `location` nil forever.
        let isFirstFix = location == nil
        guard latestLocation.horizontalAccuracy >= 0,
              isFirstFix || abs(latestLocation.timestamp.timeIntervalSinceNow) < 10 else { return }

        lastLocationError = nil
        location = latestLocation
        if isFollowingLocation {
            updateRegion(with: latestLocation)
        }
        reverseGeocode(location: latestLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastLocationError = error
        print("Error getting location: \(error.localizedDescription)")
    }
}

