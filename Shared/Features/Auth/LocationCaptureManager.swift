import Foundation
import CoreLocation

protocol LocationCaptureManaging {
    func requestSingleLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void)
}

final class LocationCaptureManager: NSObject, LocationCaptureManaging {
    private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?
    private var timeoutTimer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestSingleLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard self.completion == nil else {
            // A request is already in progress; ignore or handle accordingly
            return
        }
        self.completion = completion

        let authorizationStatus = locationManager.authorizationStatus

        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            complete(with: nil)
            return
        }

        startLocationUpdates()
    }

    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.complete(with: nil)
        }
    }

    private func complete(with coordinate: CLLocationCoordinate2D?) {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
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
