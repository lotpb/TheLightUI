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
    @EnvironmentObject var mapData: MapViewModel
    
    func makeCoordinator() -> Coordinator {
        return MapViewUI.Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let view = mapData.mapView
        view.showsUserLocation = true
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Custom Pins
            // Excluding Used Blue Circle
            if annotation.isKind(of: MKUserLocation.self) {
                return nil
            } else {
                let pinAnnotation = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PIN_VIEW")
                pinAnnotation.tintColor = .red
                //pinAnnotation.animatesDrop = true
                pinAnnotation.canShowCallout = true
                return pinAnnotation
            }
        }
    }
}

struct MapViewUI_Previews: PreviewProvider {
    static var previews: some View {
        MapViewUI()
    }
}
