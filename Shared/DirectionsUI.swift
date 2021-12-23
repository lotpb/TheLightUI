//
//  DirectionsUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI
import CoreLocation
import MapKit


struct DirectionsUI: View {
    
    @State private var from: String = "1142 Hicksville Road, Massapequa, NY, 11758"
    @State private var to: String = "Santa Monica, CA"
    
    @StateObject private var vm = DirectionsViewModel()
    
    func directionsIcon(_ instruction: String) -> String {
        if instruction.contains("right") {
            return "arrow.turn.up.right"
        } else if instruction.contains("left") {
            return "arrow.turn.up.left"
        } else if instruction.contains("destination") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Choose starting location", text: $from)
                TextField("Choose destination", text: $to)
                
                HStack {
                    Spacer()
                    Button("Search") {
                        Task {
                            await vm.calculateDirections(from: from, to: to)
                        }
                    }
                    Spacer()
                }
                
                List(vm.steps, id: \.self) { step in
                    if !step.instructions.isEmpty {
                        HStack {
                            Image(systemName: directionsIcon(step.instructions))
                            Text(step.instructions)
                        }
                    }
                }
            }
            .navigationTitle("Directions")
        }
    }
}

//@MainActor
class DirectionsViewModel: ObservableObject {
    
    @Published var steps: [MKRoute.Step] = []
    
    //NYC
    //let p1 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.71, longitude: -74))
    //Boston
    //let p2 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.36, longitude: -71.05))
    
    func calculateDirections(from: String, to: String) async {
        
        do {
            guard let startPlacemarks = try await getPlacemarksBy(address: from),
            let destinationPlaceMarks = try await getPlacemarksBy(address: to) else {
                return
            }
            
            let directionsRequest = MKDirections.Request()
            directionsRequest.transportType = .automobile
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(placemark: startPlacemarks))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(placemark: destinationPlaceMarks))
            
            let directions = MKDirections(request: directionsRequest)
            let responce = try await directions.calculate()
            
            guard let route = responce.routes.first else {
                return
            }
            
            steps = route.steps
            
        } catch {
            print(error)
        }
    }
    
    private func getPlacemarksBy(address: String) async throws -> CLPlacemark? {
        
        let geoCoder = CLGeocoder()
        let placemark = try await geoCoder.geocodeAddressString(address)
        return placemark.first
    }
}

struct DirectionsUI_Previews: PreviewProvider {
    static var previews: some View {
        DirectionsUI()
            .preferredColorScheme(.dark)
        DirectionsUI()
    }
}
