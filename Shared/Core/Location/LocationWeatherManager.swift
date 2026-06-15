//
//  LocationWeatherManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import CoreLocation
import Foundation

protocol WeatherLocationProviding {
    func requestLocation() async throws -> CLLocationCoordinate2D
}

final class LocationWeatherManager: NSObject, ObservableObject, WeatherLocationProviding {
    typealias Completion = (Result<CLLocationCoordinate2D, Swift.Error>) -> Void
    
    private static var activeManagers = [LocationWeatherManager]()
    private let manager = CLLocationManager()
    private var completion: Completion?
    
    @Published var permissionDenied = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
}

extension LocationWeatherManager {
    public func requestLocation(completion: @escaping Completion) {
        self.completion = completion
        retainForActiveRequest()
        handleAuthorizationStatus(manager.authorizationStatus)
    }
    
    public func requestLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            requestLocation { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            permissionDenied = true
            finish(with: .failure(Error.permissionDenied))
        @unknown default:
            finish(with: .failure(Error.failedToGetCoordinates))
        }
    }
    
    private func retainForActiveRequest() {
        guard !Self.activeManagers.contains(where: { $0 === self }) else { return }
        Self.activeManagers.append(self)
    }
    
    private func finish(with result: Result<CLLocationCoordinate2D, Swift.Error>) {
        DispatchQueue.main.async {
            self.completion?(result)
            self.completion = nil
            Self.activeManagers.removeAll { $0 === self }
        }
    }
}

extension LocationWeatherManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            finish(with: .failure(Error.failedToGetCoordinates))
            return
        }
        
        finish(with: .success(coordinate))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        finish(with: .failure(Error.coreLocationError(error)))
    }
}

extension LocationWeatherManager {
    enum Error: Swift.Error {
        case permissionDenied
        case failedToGetCoordinates
        case coreLocationError(Swift.Error)
    }
}
