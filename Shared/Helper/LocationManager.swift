//
//  LocationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import Foundation
import MapKit
import CoreLocation
import CoreLocationUI
import Combine


class LocationManager: NSObject, ObservableObject {
    
    @Published var mapView = MKMapView()
    // Region
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    // Map Type
    @Published var mapType: MKMapType = .standard
    ///placeListViewModel
    @Published var location: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    ///placemark
    @Published var currentPlacemark: CLPlacemark?
    ///requestLocateInfo
    private var isLocated = false
    
    var manager = CLLocationManager()
    
    
    
    //    var currentLocation: CLLocationCoordinate2D {
    //        guard let location = manager.location else {
    //            return DefaultLocation
    //        }
    //        return location.coordinate
    //    }
    //
    
    ///default NYC
    //let DefaultLocation = CLLocationCoordinate2D(latitude: 40.71, longitude: -74)
    
    public override init() {
        super.init()
        locationStatus = manager.authorizationStatus
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        //manager.allowsBackgroundLocationUpdates = true
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = true
        
        ///startUpdatingLocation
        requestLocateInfo()
        
        ///MapUI BottomSheet
        fetchGeocoder(for: manager.location)
    }
    
    func requestLocateInfo() {
            isLocated = false
            manager.startUpdatingLocation()
        }
    
    func updateMapType() {
        if mapType == .standard {
            mapType = .hybrid
        } else {
            mapType = .standard
        }
        self.mapView.mapType = mapType
    }
    
    var statusString: String {
        
        switch locationStatus {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        default: return "unknown"
        }
    }
    
    ///MapUI BottomSheet
    func fetchGeocoder(for location: CLLocation?) {
        guard let location = location else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            self.currentPlacemark = placemarks?.first
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    // Focus Location
    func focusLocation() {
        //guard let _ = region else { return }
        region = MKCoordinateRegion(center: location!.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        self.mapView.setRegion(region, animated: true)
        self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, animated: true)
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func startUpdating() {
        print("****** Location started updated")
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        print("***** Location updates stopping")
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        //print(#function, statusString)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        print("****** Location updated")
        DispatchQueue.main.async {
            self.location = manager.location
            self.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            //self.mapView.setRegion(self.region, animated: true)
            //self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, animated: true)
            //print(#function, location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error getting location \(error.localizedDescription)")
    }
}


