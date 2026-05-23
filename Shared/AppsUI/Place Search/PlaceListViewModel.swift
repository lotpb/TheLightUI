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
    
    private let locationManager = LocationManager()
    private var cancellable: AnyCancellable?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var landMarks: [LandMark] = []
    
    init() {
        cancellable = locationManager.$location.sink { [weak self] location in
            guard let self, let location else { return }
            DispatchQueue.main.async {
                self.currentLocation = location.coordinate
                self.locationManager.stopUpdating()
            }
        }
    }
    
    func searchLandmarks(_ searchTerm: String) {
        let trimmedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchTerm.isEmpty else {
            landMarks = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedSearchTerm
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            if let error = error {
                print(error)
                return
            }
            
            let landMarks = response?.mapItems.map { mapItem in
                LandMark(displayPhone: "", placemark: mapItem.placemark)
            } ?? []
            
            DispatchQueue.main.async {
                self?.landMarks = landMarks
            }
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
