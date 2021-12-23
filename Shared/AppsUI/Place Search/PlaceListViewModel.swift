//
//  PlaceListViewModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import Foundation
import Combine
//import CoreLocation
import MapKit
import SwiftUI


class PlaceListViewModel: ObservableObject {
    
    @State var locationManager = LocationManager()
    var cancellable: AnyCancellable?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var landMarks: [LandMark] = []
    
    init() {
        //locationManager.startUpdates()
        
        cancellable = locationManager.$location.sink { location in
            if let location = location {
                DispatchQueue.main.async { [self] in
                    self.currentLocation = location.coordinate
                    self.locationManager.stopUpdating()///not working
                }
                
            }
        }
    }
    
    func searchLandmarks(_ searchTerm: String) {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print(error)
            } else if let response = response {
                
                let mapItems = response.mapItems
                // populate the landmarks
                self.landMarks = mapItems.map { mapItem in
                    return LandMark(display_phone: "", placemark: mapItem.placemark)
                }
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
