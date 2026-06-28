//
//  PlaceListViewModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import Foundation
import MapKit
import Observation

@MainActor
@Observable
class PlaceListViewModel {
    @ObservationIgnored private let placeSearchService: PlaceSearchServicing

    var landMarks: [LandMark] = []
    private(set) var errorMessage = ""

    init(placeSearchService: PlaceSearchServicing) {
        self.placeSearchService = placeSearchService
    }

    func searchLandmarks(_ searchTerm: String) {
        let trimmedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchTerm.isEmpty else {
            landMarks = []
            errorMessage = ""
            return
        }

        Task {
            do {
                landMarks = try await placeSearchService.searchLandmarks(matching: trimmedSearchTerm)
                errorMessage = ""
            } catch {
                landMarks = []
                errorMessage = error.localizedDescription
            }
        }
    }
}

protocol PlaceSearchServicing {
    func searchLandmarks(matching searchTerm: String) async throws -> [LandMark]
    func searchPlaces(matching searchTerm: String) async throws -> [LandMark]
}

struct MKLocalPlaceSearchService: PlaceSearchServicing {
    func searchLandmarks(matching searchTerm: String) async throws -> [LandMark] {
        let mapItems = try await search(matching: searchTerm)
        return mapItems.map { LandMark(displayPhone: "", placemark: $0.placemark) }
    }

    func searchPlaces(matching searchTerm: String) async throws -> [LandMark] {
        try await searchLandmarks(matching: searchTerm)
    }

    private func search(matching searchTerm: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm

        return try await withCheckedThrowingContinuation { continuation in
            MKLocalSearch(request: request).start { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: response?.mapItems ?? [])
            }
        }
    }
}

/// NYC
extension MKCoordinateRegion {
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 26.4649, longitude: -80.124), //Delray Beach
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }
}
