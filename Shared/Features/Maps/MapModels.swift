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

    var address: String {
        "\(street) \(city), \(state) \(zip)"
    }

    var displayName: String {
        "\(street), \(city)"
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
