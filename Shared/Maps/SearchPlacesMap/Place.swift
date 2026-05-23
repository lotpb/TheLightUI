//
//  Place.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/21/21.
//

import CoreLocation
import MapKit

struct Place: Identifiable {
    let id: String
    let placemark: CLPlacemark

    init(placemark: CLPlacemark) {
        self.placemark = placemark
        id = Self.identifier(for: placemark)
    }

    var name: String {
        placemark.name?.isEmpty == false ? placemark.name! : "Unknown Place"
    }

    var subtitle: String? {
        let parts = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private static func identifier(for placemark: CLPlacemark) -> String {
        if let coordinate = placemark.location?.coordinate {
            return "\(coordinate.latitude),\(coordinate.longitude)-\(placemark.name ?? "")"
        }

        return placemark.name ?? UUID().uuidString
    }
}
