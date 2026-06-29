import Foundation
import CoreLocation

protocol LocationCaptureManaging {
    /// Request a single location fix, returning `nil` if permission is denied or the request times out.
    func requestSingleLocation() async -> CLLocationCoordinate2D?
}

final class LocationCaptureManager: NSObject, LocationCaptureManaging {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?
    private var timeoutTimer: Timer?
    private var isUpdatingLocation = false

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestSingleLocation() async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            requestSingleLocation { coordinate in
                continuation.resume(returning: coordinate)
            }
        }
    }

    private func requestSingleLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard self.completion == nil else {
            // A request is already in progress; report no result for this one.
            completion(nil)
            return
        }
        self.completion = completion

        let authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .denied, .restricted:
            complete(with: nil)
        @unknown default:
            complete(with: nil)
        }
    }

    private func startLocationUpdates() {
        guard !isUpdatingLocation else { return }

        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.complete(with: nil)
        }
    }

    private func complete(with coordinate: CLLocationCoordinate2D?) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        if let completion = self.completion {
            self.completion = nil
            completion(coordinate)
        }
    }
}

extension LocationCaptureManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if completion != nil {
                startLocationUpdates()
            }
        case .denied, .restricted:
            complete(with: nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        complete(with: location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        complete(with: nil)
    }
}
