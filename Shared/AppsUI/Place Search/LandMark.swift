//
//  LandMark.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import Foundation
import MapKit


struct LandMark: Identifiable {
    let id: UUID = UUID()
    
    let display_phone: String
    
    let placemark: MKPlacemark
    
    var name: String {
        placemark.name ?? ""
    }
    
    var title: String {
        placemark.title ?? ""
    }
    
    var coordinate: CLLocationCoordinate2D {
        placemark.coordinate
    }
}
