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
        configure(view)
        return view
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if view.delegate !== context.coordinator {
            view.delegate = context.coordinator
        }
        configure(view)
    }

    static func dismantleUIView(_ view: MKMapView, coordinator: Coordinator) {
        view.delegate = nil
    }

    private func configure(_ view: MKMapView) {
        view.showsUserLocation = true
        view.userTrackingMode = .follow
        view.pointOfInterestFilter = .includingAll
        view.showsCompass = false
        view.showsScale = false
        view.showsTraffic = false
        view.isRotateEnabled = true
        view.isPitchEnabled = true
        view.tintColor = .systemBlue
        view.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.placeReuseIdentifier)
        view.register(MKUserLocationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.userReuseIdentifier)

        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .unspecified
        }

        if #available(iOS 16.0, *) {
            view.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
        } else {
            view.mapType = .mutedStandard
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        static let placeReuseIdentifier = "PLACE_PIN_VIEW"
        static let userReuseIdentifier = "USER_LOCATION_VIEW"

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return userLocationView(for: annotation, in: mapView)
            }

            return placeMarkerView(for: annotation, in: mapView)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !(view.annotation is MKUserLocation) else { return }
            mapView.setCenter(view.annotation?.coordinate ?? mapView.centerCoordinate, animated: true)
        }

        private func placeMarkerView(for annotation: MKAnnotation, in mapView: MKMapView) -> MKMarkerAnnotationView? {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Self.placeReuseIdentifier,
                for: annotation
            ) as? MKMarkerAnnotationView

            annotationView?.annotation = annotation
            annotationView?.markerTintColor = .systemBlue
            annotationView?.glyphTintColor = .white
            annotationView?.glyphImage = UIImage(systemName: "mappin")
            annotationView?.titleVisibility = .adaptive
            annotationView?.subtitleVisibility = .adaptive
            annotationView?.animatesWhenAdded = true
            annotationView?.displayPriority = .required
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = calloutButton()
            return annotationView
        }

        private func userLocationView(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Self.userReuseIdentifier,
                for: annotation
            ) as? MKUserLocationView

            annotationView?.annotation = annotation
            annotationView?.tintColor = .systemBlue
            return annotationView
        }

        private func calloutButton() -> UIButton {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.circle.fill"), for: .normal)
            button.tintColor = .systemBlue
            button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            return button
        }
    }
}

#Preview("Map View") {
    MapViewUI()
        .environmentObject(MapViewModel())
}
