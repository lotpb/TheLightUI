//
//  SwiftUIMap.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/3/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import MapKit
import CoreLocation


class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var mapView = MKMapView()
    
    // Region
    @Published var region = MKCoordinateRegion.defaultRegion
    // Based on Location it will set up
    
    // Alert
    @Published var permissionDenied = false
    
    // SearchText
    @Published var searchTxt = ""
    
    // Searched Places
    @Published var places: [Place] = []
    
    // Search Places
    func searchQuery() {
        let trimmedSearchText = searchTxt.trimmingCharacters(in: .whitespacesAndNewlines)
        places.removeAll()
        guard !trimmedSearchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedSearchText
        
        // Fetch
        MKLocalSearch(request: request).start { [weak self] response, _ in
            guard let result = response else { return }
            
            let places = result.mapItems.map { item in
                Place(placemark: item.placemark)
            }
            
            DispatchQueue.main.async {
                self?.places = places
            }
        }
    }
    
    // Pick Search Result
    func selectPlace(place: Place) {
        // Showing Pin on Map
        searchTxt = ""
        
        guard let coordinate = place.placemark.location?.coordinate else { return }
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = place.placemark.name ?? "No Name"
        
        // Removing All Old Ones
        mapView.removeAnnotations(mapView.annotations)
        
        mapView.addAnnotation(pointAnnotation)
        
        // Moving Map To That Location
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.setVisibleMapRect(mapView.visibleMapRect, animated: true)
    }
    
}
