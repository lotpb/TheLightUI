//
//  LocationManager2.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import Foundation
import CoreLocation
//import MapKit

class LocationWeatherManager: NSObject, ObservableObject {
    
    ///Weather App
    typealias Completion = (Result<CLLocationCoordinate2D, Swift.Error>) -> Void
    
    private static var instances = [LocationWeatherManager]()
    private let manager = CLLocationManager()
    private var completion: Completion?
    
    //    @Published var location: CLLocation?
    //    @Published var region: MKCoordinateRegion = MKCoordinateRegion.init()
        @Published var permissionDenied = false

    override init() {
        super.init()
        
        manager.delegate = self
    }
}

extension LocationWeatherManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Checking Permissions
        switch manager.authorizationStatus {
        case .denied:
            // Alert
            permissionDenied.toggle()
        case .notDetermined:
            // Requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // If Permission Given
            manager.requestLocation()
        default:
            ()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        ///Weather App
        if let location = locations.first?.coordinate {
            self.completion?(.success(location))
        } else {
            self.completion?(.failure(Error.failedToGetCoordinates))
        }
        Self.instances.removeAll(where: {$0 === self})
    }
    ///Weather App
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
            self.completion?(.failure(Error.coreLocationError(error)))
            Self.instances.removeAll(where: {$0 === self})
        }
}

///WeatherUI App
extension LocationWeatherManager {
    // MARK: Public interface
    public func requestLocation(completion: @escaping Completion) {
        self.completion = completion
        Self.instances.append(self)
        manager.requestLocation()
    }
}

///WeatherUI App
extension LocationWeatherManager {
    // MARK: Nested objects
    enum Error: Swift.Error {
        case failedToGetCoordinates
        case coreLocationError(Swift.Error)
    }
}
