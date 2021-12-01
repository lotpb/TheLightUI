//
//  LocationButtonUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 6/14/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

import CoreLocationUI
import CoreLocation
import MapKit

@available(iOS 15.0, *)
struct LocationButtonUI: View {
    
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: locationManager.coffeeShops, annotationContent: { shop in
         
                MapMarker(coordinate: shop.mapItem.placemark.coordinate, tint: .purple)
                
            })
                .ignoresSafeArea()
            
            LocationButton(.currentLocation) {
                
                locationManager.manager.requestLocation()
            }
            .frame(width: 210, height: 50)
            .symbolVariant(.fill)
            .foregroundColor(.white)
            .tint(.purple)
            .clipShape(Capsule())
            .padding()
        }
        
        .overlay(
            
            Text("Local Parks")
            //Text("Coffee Shop's")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                ,alignment: .top
        )
    }
}


@available(iOS 15.0, *)
struct LocationButtonUI_Previews: PreviewProvider {
    static var previews: some View {
        LocationButtonUI()
    }
}

@available(iOS 15.0, *)
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var manager = CLLocationManager()
    
    @Published var region : MKCoordinateRegion = .init()
    
    @Published var coffeeShops : [Shop] = []
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last?.coordinate else {
            return
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.010)
        region = MKCoordinateRegion(center: location, span: span)
        
        Task {
            await fetchCoffeeShops()
        }
    }
    
    func fetchCoffeeShops()async {
        
        do {
            let request = MKLocalSearch.Request()
            request.region = region
            request.naturalLanguageQuery = "Park"
            //request.naturalLanguageQuery = "Coffee Shops"
            
            let query = MKLocalSearch(request: request)
            
            let response = try await query.start()
            
            await MainActor.run {
                
                self.coffeeShops = response.mapItems.compactMap { item in
                    
                    return Shop(mapItem: item)
                }
            }
        }
        catch {
            
        }
    }
}

struct Shop: Identifiable {
    var id = UUID().uuidString
    var mapItem: MKMapItem
}
