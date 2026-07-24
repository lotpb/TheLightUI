//
//  MapModels.swift
//  TheLightUI
//

import Foundation

struct MapDestination: Equatable {
    let street: String
    let city: String
    let state: String
    let zip: String

    // Convenience init for a free-form address string (e.g. from a saved favorite).
    init(rawAddress: String) {
        self.street = rawAddress
        self.city = ""
        self.state = ""
        self.zip = ""
    }

    init(street: String, city: String, state: String, zip: String) {
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
    }

    var address: String {
        // When created from a raw address string the other fields are empty.
        if city.isEmpty && state.isEmpty && zip.isEmpty { return street }
        return "\(street) \(city), \(state) \(zip)"
    }

    var displayName: String {
        city.isEmpty ? street : "\(street), \(city)"
    }
}

enum MapMode: Equatable {
    case currentLocation
    case route(destination: MapDestination)
}

enum RouteStatus: Equatable {
    case idle
    case loading
    case ready
    case failed(String)
}

struct MapRouteStep: Identifiable, Hashable {
    let id = UUID()
    let instructions: String
    let distanceText: String
    let travelTimeText: String
}
