//
//  LocationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import CoreLocation
import MapKit

final class LocationManager: NSObject, ObservableObject {
    @Published var mapView = MKMapView()
    @Published var region = MKCoordinateRegion.defaultRegion
    @Published var mapType: MKMapType = .standard
    @Published var location: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentPlacemark: CLPlacemark?
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let regionDistance: CLLocationDistance = 10000
    
    override init() {
        super.init()
        configureLocationManager()
        requestLocateInfo()
    }
    
    func requestLocateInfo() {
        handleAuthorizationStatus(manager.authorizationStatus)
    }
    
    func updateMapType() {
        mapType = mapType == .standard ? .hybrid : .standard
        mapView.mapType = mapType
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
    
    func fetchGeocoder(for location: CLLocation?) {
        guard let location else { return }
        
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error {
                print("Error reverse geocoding location: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self?.currentPlacemark = placemarks?.first
            }
        }
    }
    
    func focusLocation() {
        guard let location else { return }
        
        let newRegion = makeRegion(for: location)
        region = newRegion
        mapView.setRegion(newRegion, animated: true)
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
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
        requestLocateInfo()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
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
        updateAuthorizationStatus(status)
        
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
    }
    
    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationStatus = status
        }
    }
    
    private func makeRegion(for location: CLLocation) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionDistance,
            longitudinalMeters: regionDistance
        )
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        let newRegion = makeRegion(for: latestLocation)
        
        DispatchQueue.main.async {
            self.location = latestLocation
            self.region = newRegion
            self.fetchGeocoder(for: latestLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
}
