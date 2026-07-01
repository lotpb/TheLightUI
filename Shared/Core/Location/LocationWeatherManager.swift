//
//  LocationWeatherManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import CoreLocation
import Foundation
import Observation

protocol WeatherLocationProviding {
    @MainActor func requestLocation() async throws -> CLLocationCoordinate2D
}

@MainActor
@Observable
final class LocationWeatherManager: NSObject, WeatherLocationProviding {
    typealias Completion = (Result<CLLocationCoordinate2D, Swift.Error>) -> Void

    @ObservationIgnored nonisolated(unsafe) private let manager = CLLocationManager()
    @ObservationIgnored private var completion: Completion?
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?
    @ObservationIgnored private let requestTimeout: Duration

    var permissionDenied = false

    nonisolated init(requestTimeout: Duration = .seconds(10)) {
        self.requestTimeout = requestTimeout
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    deinit {
        // `manager` is owned solely by this instance and holds only a weak
        // reference back via its delegate, so CoreLocation stops updating and
        // tears down automatically as this object deallocates.
        timeoutTask?.cancel()
    }
}

@MainActor
extension LocationWeatherManager {
    public func requestLocation(completion: @escaping Completion) {
        guard self.completion == nil else {
            completion(.failure(Error.requestInProgress))
            return
        }

        self.completion = completion
        startTimeout()
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    public func requestLocation() async throws -> CLLocationCoordinate2D {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestLocation { result in
                    continuation.resume(with: result)
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finish(with: .failure(CancellationError()))
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

    private func startTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self, requestTimeout] in
            do {
                try await Task.sleep(for: requestTimeout)
            } catch {
                return
            }

            self?.finish(with: .failure(Error.timedOut))
        }
    }

    private func finish(with result: Result<CLLocationCoordinate2D, Swift.Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.stopUpdatingLocation()

        guard let completion else { return }
        self.completion = nil
        completion(result)
    }
}

extension LocationWeatherManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.handleAuthorizationStatus(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor [weak self] in
            guard let coordinate else {
                self?.finish(with: .failure(Error.failedToGetCoordinates))
                return
            }

            self?.finish(with: .success(coordinate))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        Task { @MainActor [weak self] in
            self?.finish(with: .failure(Error.coreLocationError(error)))
        }
    }
}

extension LocationWeatherManager {
    enum Error: LocalizedError {
        case permissionDenied
        case failedToGetCoordinates
        case coreLocationError(Swift.Error)
        case requestInProgress
        case timedOut

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission is denied."
            case .failedToGetCoordinates:
                return "Could not get your current coordinates."
            case .coreLocationError(let error):
                return error.localizedDescription
            case .requestInProgress:
                return "A location request is already in progress."
            case .timedOut:
                return "Location request timed out."
            }
        }
    }
}
