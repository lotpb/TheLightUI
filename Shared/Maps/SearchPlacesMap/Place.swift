//
//  Place.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/21/21.
//

import SwiftUI
import MapKit

struct Place: Identifiable {
    
    var id = UUID().uuidString
    var placemark: CLPlacemark
}
