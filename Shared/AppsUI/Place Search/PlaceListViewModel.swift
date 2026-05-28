//
//  PlaceListViewModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import Foundation
import Combine
import MapKit


class PlaceListViewModel: ObservableObject {
    
    private let locationProvider: CurrentLocationProviding
    private let placeSearchService: PlaceSearchServicing
    private var cancellable: AnyCancellable?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var landMarks: [LandMark] = []
    
    init(locationProvider: CurrentLocationProviding, placeSearchService: PlaceSearchServicing) {
        self.locationProvider = locationProvider
        self.placeSearchService = placeSearchService

        cancellable = locationProvider.locationPublisher.sink { [weak self] location in
            guard let self, let location else { return }
            DispatchQueue.main.async {
                self.currentLocation = location.coordinate
                self.locationProvider.stopUpdating()
            }
        }
    }
    
    func searchLandmarks(_ searchTerm: String) {
        let trimmedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchTerm.isEmpty else {
            landMarks = []
            return
        }
        
        placeSearchService.searchLandmarks(matching: trimmedSearchTerm) { [weak self] result in
            switch result {
            case .success(let landMarks):
                DispatchQueue.main.async {
                    self?.landMarks = landMarks
                }
            case .failure(let error):
                print(error.localizedDescription)
                return
            }
        }
    }
}

protocol CurrentLocationProviding {
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    func stopUpdating()
}

extension LocationManager: CurrentLocationProviding {
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $location.eraseToAnyPublisher()
    }
}

protocol PlaceSearchServicing {
    func searchLandmarks(matching searchTerm: String, completion: @escaping (Result<[LandMark], Error>) -> Void)
    func searchPlaces(matching searchTerm: String, completion: @escaping (Result<[Place], Error>) -> Void)
}

struct MKLocalPlaceSearchService: PlaceSearchServicing {
    func searchLandmarks(matching searchTerm: String, completion: @escaping (Result<[LandMark], Error>) -> Void) {
        search(matching: searchTerm) { result in
            completion(result.map { mapItems in
                mapItems.map { LandMark(displayPhone: "", placemark: $0.placemark) }
            })
        }
    }

    func searchPlaces(matching searchTerm: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        search(matching: searchTerm) { result in
            completion(result.map { mapItems in
                mapItems.map { Place(placemark: $0.placemark) }
            })
        }
    }

    private func search(matching searchTerm: String, completion: @escaping (Result<[MKMapItem], Error>) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm

        MKLocalSearch(request: request).start { response, error in
            if let error {
                completion(.failure(error))
                return
            }

            completion(.success(response?.mapItems ?? []))
        }
    }
}

/// NYC
extension MKCoordinateRegion {
    static var defaultRegion: MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.71, longitude: -74),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }
    
}
