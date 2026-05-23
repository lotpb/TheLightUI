//
//  MapView.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/3/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
import MapKit

struct MapViewUI: UIViewRepresentable {
    @EnvironmentObject private var mapData: MapViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let view = mapData.mapView
        view.delegate = context.coordinator
        view.showsUserLocation = true
        view.userTrackingMode = .follow
        view.pointOfInterestFilter = .includingAll
        view.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.reuseIdentifier)
        return view
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if view.delegate !== context.coordinator {
            view.delegate = context.coordinator
        }
    }

    static func dismantleUIView(_ view: MKMapView, coordinator: Coordinator) {
        view.delegate = nil
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        static let reuseIdentifier = "PIN_VIEW"

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Self.reuseIdentifier,
                for: annotation
            ) as? MKMarkerAnnotationView

            annotationView?.annotation = annotation
            annotationView?.markerTintColor = .systemRed
            annotationView?.glyphImage = UIImage(systemName: "mappin")
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !(view.annotation is MKUserLocation) else { return }
            mapView.setCenter(view.annotation?.coordinate ?? mapView.centerCoordinate, animated: true)
        }
    }
}

#Preview("Map View") {
    MapViewUI()
        .environmentObject(MapViewModel())
}
