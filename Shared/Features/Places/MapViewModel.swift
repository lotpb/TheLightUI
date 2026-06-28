//
//  SwiftUIMap.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/3/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import MapKit
import CoreLocation
import Observation


@Observable
class MapViewModel: NSObject, CLLocationManagerDelegate {
    
    var mapView: MKMapView
    @ObservationIgnored private let placeSearchService: PlaceSearchServicing
    
    // Region
    var region = MKCoordinateRegion.defaultRegion
    // Based on Location it will set up
    
    // Alert
    var permissionDenied = false
    
    // SearchText
    var searchTxt = ""
    
    // Searched Places
    var places: [LandMark] = []

    init(mapView: MKMapView, placeSearchService: PlaceSearchServicing) {
        self.mapView = mapView
        self.placeSearchService = placeSearchService
        super.init()
    }
    
    // Search Places
    func searchQuery() {
        let trimmedSearchText = searchTxt.trimmingCharacters(in: .whitespacesAndNewlines)
        places.removeAll()
        guard !trimmedSearchText.isEmpty else { return }
        
        Task { [weak self] in
            do {
                self?.places = try await self?.placeSearchService.searchPlaces(matching: trimmedSearchText) ?? []
            } catch {
                self?.places = []
            }
        }
    }
    
    // Pick Search Result
    func selectPlace(place: LandMark) {
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
