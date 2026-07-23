import Foundation
import CoreLocation

protocol LocationCaptureManaging: Sendable {
    /// Request a single location fix, returning `nil` if permission is denied or the request times out.
    func requestSingleLocation() async -> CLLocationCoordinate2D?
}

@MainActor
final class LocationCaptureManager: NSObject, LocationCaptureManaging {
    nonisolated(unsafe) private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?
    private var timeoutTask: Task<Void, Never>?
    private var isUpdatingLocation = false

    nonisolated override init() {
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

        switch locationManager.authorizationStatus {
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
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            self?.complete(with: nil)
        }
    }

    private func complete(with coordinate: CLLocationCoordinate2D?) {
        timeoutTask?.cancel()
        timeoutTask = nil
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        if let completion = self.completion {
            self.completion = nil
            completion(coordinate)
        }
    }
}

extension LocationCaptureManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                if self.completion != nil {
                    self.startLocationUpdates()
                }
            case .denied, .restricted:
                self.complete(with: nil)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor [weak self] in
            self?.complete(with: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.complete(with: nil)
        }
    }
}
