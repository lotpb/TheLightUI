//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import MapKit
//import CoreLocation
import CoreLocationUI
import SDWebImageSwiftUI

struct MapUI: View {
    @StateObject private var manager = LocationManager()
    //@State var manager = CLLocationManager()
    @State private var directions: [String] = []
    //@State var mapType: MKMapType
    //let mapType : MKMapType = .standard
    //@State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var offset : CGFloat = 0
    @State private var isDragged: Bool = false

    @State var mapstreet = "1142 Hicksville Road"
    @State var mapcity = "Massapequa"
    @State var mapstate = "Ny"
    @State var mapzip = "11758"
    
    @State var travelTime: Double
    @State var distance: Double
    
    @State private var region = MKCoordinateRegion()

    
    var body: some View {
        
        ZStack(alignment: .top) {
            MapView(travelTime: $travelTime, distance: $distance, directions: $directions, mapstreet: $mapstreet, mapcity: $mapcity, mapstate: $mapstate, mapzip: $mapzip, region: $manager.region, mapType: .standard)
                .ignoresSafeArea(.all, edges: .all)
//                .gesture(
//                    DragGesture()
//                        .onChanged({ value in
//                            isDragged = true
//                            //locationManager.stopUpdating()
//                        })
//                )
//                .overlay(
//                    isDragged ?
//                    AnyView(LocationButton(.shareCurrentLocation) {
//                        manager.requestLocation()
//                        //locationManager.stopUpdating()
//                        isDragged = false
//                        //locationManager.startUpdating()
//                    }
//                    .padding()) : AnyView(EmptyView()), alignment: .center
//                )
            
            
            MapButtonView( directions: $directions)
            
            ///BottomSheetUI
            GeometryReader { reader in
                VStack {
                    BottomSheetUI(offset: $offset, value: (-reader.frame(in: .global).height + 150), travelTime: $travelTime, distance: $distance)
                        .offset(y: reader.frame(in: .global).height - 60)
                        .offset(y: offset)
                        .gesture(DragGesture().onChanged({ (value) in
                            withAnimation{
                                if value.startLocation.y > reader.frame(in: .global).midX{
                                    if value.translation.height < 0 && offset > (-reader.frame(in: .global).height + 150){
                                        offset = value.translation.height
                                    }
                                }
                                if value.startLocation.y < reader.frame(in: .global).midX{
                                    if value.translation.height > 0 && offset < 0{
                                        offset = (-reader.frame(in: .global).height + 150) + value.translation.height
                                    }
                                }
                            }
                        }).onEnded({ (value) in
                            withAnimation{
                                // checking and pulling up the screen...
                                if value.startLocation.y > reader.frame(in: .global).midX{
                                    if -value.translation.height > reader.frame(in: .global).midX{
                                        offset = (-reader.frame(in: .global).height + 150)
                                        return
                                    }
                                    offset = 0
                                }
                                
                                if value.startLocation.y < reader.frame(in: .global).midX{
                                    if value.translation.height < reader.frame(in: .global).midX{
                                        offset = (-reader.frame(in: .global).height + 150)
                                        return
                                    }
                                    offset = 0
                                }
                            }
                        }))
                }
            }
            
        }
        .onAppear {
            manager.startUpdating()
            //manager.delegate = locationManager
        }
        .onDisappear {
            manager.stopUpdating()
        }
    }
}

struct MapView : UIViewRepresentable {

    @ObservedObject var manager = LocationManager()
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var directions: [String]
    
    @Binding var mapstreet: String
    @Binding var mapcity: String
    @Binding var mapstate: String
    @Binding var mapzip: String
    //@Binding var mapType: String
    
    @Binding var region: MKCoordinateRegion
    
    let mapType : MKMapType
    
    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // uiView.addAnnotations(checkpoints)
        DispatchQueue.main.async {
            uiView.region = region
            uiView.setRegion(region, animated: true)
            uiView.setVisibleMapRect(uiView.visibleMapRect, animated: true)
            uiView.mapType = MKMapType.standard
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        
        //MapView.centerCoordinate = mapView.centerCoordinate
        //MapView.centerCoordinate.center = mapView.centerCoordinate
    }
    
    func makeUIView(context: Context) -> MKMapView {
        
        let mapView = manager.mapView
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.pointOfInterestFilter = .init(including: [.evCharger, .gasStation])
        mapView.showsBuildings = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        //mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.userTrackingMode = .follow
        //mapView.mapType = mapType
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true
        
        let address = "\(mapstreet) \(mapcity), \(mapstate) \(mapzip)"
        let endPoint = "\(mapstreet), \(mapcity)"
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
            
            if let placemarks = placemarks,
               let location = placemarks.first?.location {
               
                let sourceCoordinate = MKPlacemark(coordinate: manager.location!.coordinate)
                
                let desinationCoordinate = MKPlacemark(coordinate: location.coordinate)
                
                region = MKCoordinateRegion.init(center: manager.region.center, latitudinalMeters: 500.0, longitudinalMeters: 500.0)
                
                let sourcePin = MKPointAnnotation()
                sourcePin.coordinate = sourceCoordinate.coordinate
                sourcePin.title = "Start"
                sourcePin.subtitle = "Current Location"
                
                ///Boston
                //let p2 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.36, longitude: -71.05))
                let destPin = MKPointAnnotation()
                destPin.coordinate = desinationCoordinate.coordinate
                destPin.title = "Destination"
                destPin.subtitle = endPoint
                
                ///Directions
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: sourceCoordinate)
                request.destination = MKMapItem(placemark: desinationCoordinate)
                request.transportType = .automobile
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    
                    guard let route = response?.routes.first else { return }
                    travelTime = route.expectedTravelTime
                    distance = route.distance
                    
                    mapView.removeAnnotations(mapView.annotations)
                    mapView.removeOverlays(mapView.overlays)
                    mapView.addAnnotations([sourcePin, destPin])
                    mapView.addOverlay(route.polyline)
                    mapView.setVisibleMapRect(
                        route.polyline.boundingMapRect,
                        edgePadding: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25),
                        animated: true)
                    
                    self.directions = route.steps.map { $0.instructions }.filter { !$0.isEmpty }
                    mapView.setRegion(region, animated: true)
                }
            }
        })
        
        return mapView
    }
    
    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.blue)
            renderer.lineWidth = 6
            renderer.lineCap = .round
            return renderer
        }
    }
    
}

struct MapButtonView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager = LocationManager()
    @State private var showDirections = false
    @Binding var directions: [String]
   // @Binding var mapType: MKMapType
    //let mapType : MKMapType
    
    var body: some View {
        HStack {
            VStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("taylor_swift_profile")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Button(action:  {
                    self.showDirections.toggle()
                }) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title2)
                        .padding(10)
                        .background(Color.secondary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                .padding(.bottom, 60)
                //.disabled(directions.isEmpty)
            }.padding(.horizontal)
            
            Spacer()
            
            VStack {
                let s = 2.23694 * (manager.location?.speed ?? 0.0)
                let speedStr = String(format: "Speed: %.0f", s)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text(speedStr)
                        .foregroundColor(Color.primary)
                        .font(.caption)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                })
                    .frame(width: 120, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 50, style: .continuous).fill(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 50, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                
                Spacer()
            }
            
            Spacer()
            
            VStack {
                Button {
                    manager.updateMapType()
                } label: {
                    Image(systemName: manager.mapType == .standard ? "network" : "map")
                        .font(.title2)
                        .padding(10)
                        .background(Color.secondary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                
                Spacer()
                
                LocationButton {
                                manager.requestLocation()
                            }
                            //.frame(width: 60, height: 60)
                            .labelStyle(.iconOnly)
                            .symbolVariant(.fill)
                            .foregroundColor(.white)
                            //.background(Color.secondary)
                            .clipShape(Circle())
                            //.cornerRadius(30)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                
//                Button(action: {
//                   // MapView.setRegion(self.centerCoordinate, animated: true)
//                    manager.focusLocation()
//
//                }) {
//                    Image(systemName: "location.fill")
//                        .font(.title2)
//                        .padding(10)
//                        .background(Color.secondary)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
//                }
               .padding(.bottom, 60)
            }.padding(.horizontal)
            
                .sheet(isPresented: $showDirections) {
                    VStack(spacing: 0) {
                        Text("Directions")
                            .font(.largeTitle).bold()
                            .padding()
                        
                        Divider().background(Color.secondary)
                        
                        List(0..<self.directions.count, id: \.self) { i in
                            if !self.directions.isEmpty {
                                    HStack {
                                        Image(systemName: directionsIcon(self.directions[i]))
                                        Text(self.directions[i]).padding()
                                    }//.background(Color.blue)
                                
                            }
                        }.background(Color.white)
                    }.background(Color.white)
                }
        }
        .padding()
    }
    
    func directionsIcon(_ instruction: String) -> String {
        if instruction.contains("destination") {
            return "mappin.circle.fill"
        } else if instruction.contains("right") {
            return "arrow.turn.up.right"
        } else if instruction.contains("left") {
            return "arrow.turn.up.left"
        } else {
            return "arrow.up"
        }
    }
    
}

struct BottomSheetUI : View {
    @State private var vm = MainMessagesViewModel()
    @ObservedObject var locationManager = LocationManager()
    @Binding var offset : CGFloat
    var value : CGFloat
    @Binding var travelTime: Double
    @Binding var distance: Double
    
    var body: some View {
        let s = 2.23694 * (locationManager.location?.speed ?? 0.0)
        let speedStr = String(format: "Speed: %.0f", s)
        
        let altitudeStr = String(format: "Altitude: %.0f", locationManager.location?.altitude ?? 0)
        let latStr = String(format: "Latitude: %.0f", locationManager.location?.coordinate.latitude ?? 0)
        let longStr = String(format: "longitude: %.0f", locationManager.location?.coordinate.longitude ?? 0)
        let coarseStr = String(format: "Course: %.0f", locationManager.location?.course ?? 0)
        
        VStack {
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 50, height: 5)
                .padding(.top, 7)
            
            HStack(spacing: 0){
                
                Text("Go Online").font(.system(size: 20, weight: .semibold))
                    .padding(.top, -18)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .overlay(alignment: .trailing) {
                        WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .clipShape(Circle()).clipped()
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .padding(.trailing, 20).padding(.bottom, 14).shadow(radius: 5)
                    }
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading){
                            HStack {
                                Image(systemName: "car")
                                    .foregroundColor(.blue)
                                Text(String(format:"%0.0f min", travelTime/60))
                            }
                            Spacer()
                                .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                                .fixedSize()
                            HStack {
                                Image(systemName: "bolt.car.fill")
                                    .foregroundColor(.blue)
                                Text(String(format:"%0.0f miles", distance/1609.344))
                                    .padding(.bottom, 10)
                            }
                        }
                        .padding(.leading, 15)
                        .foregroundColor(Color(.white))
                        .font(.caption.bold())
                    }
            }
            .foregroundColor(.white)
            .cornerRadius(15)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("Favorites")
                        .font(.headline.bold())
                        .foregroundColor(Color("AccentColor"))
                        .padding()
                    
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        HStack {
                            VStack {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "house.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Text("Home")
                                    .font(.headline.bold())
                                    .foregroundColor(Color("AccentColor"))
                            }
                            .padding()
                            VStack {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "briefcase.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding()
                                        .background(Color.gray)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Text("Work")
                                    .font(.headline.bold())
                                    .foregroundColor(Color("AccentColor"))
                                
                            }
                            
                            .padding()
                            VStack {
                                Button {
                                    
                                } label: {
                                    Image(systemName: "mappin")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .padding()
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Text("Add")
                                    .font(.headline.bold())
                                    .foregroundColor(Color("AccentColor"))
                            }
                            .padding()
                        }
                    }
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    
                    Spacer()
                    Group {
                        VStack {
                            Text("\(String(locationManager.currentPlacemark?.subThoroughfare ?? "No Address")) \(String(locationManager.currentPlacemark?.thoroughfare ?? ""))\n\(String(locationManager.currentPlacemark?.locality ?? "")) \(String(locationManager.currentPlacemark?.administrativeArea ?? "")) \(String(locationManager.currentPlacemark?.postalCode ?? ""))\n\(String(locationManager.currentPlacemark?.country ?? ""))")
                        }.padding().font(.callout.bold())
                        HStack {
                            Text("Location Data")
                                .font(.headline.bold())
                                .foregroundColor(Color("AccentColor"))
                                .padding()
                        }
                        
                        HStack {
                            Text(altitudeStr)
                        }.padding().lineLimit(1).font(.callout.bold())
                        HStack {
                            Text(speedStr)
                        }.padding().lineLimit(1).font(.callout.bold())
                        HStack {
                            Text(latStr)
                        }.padding().lineLimit(1).font(.callout.bold())
                        HStack {
                            Text(longStr)
                        }.padding().lineLimit(1).font(.callout.bold())
                        HStack {
                            Text(coarseStr)
                        }.padding().lineLimit(1).font(.callout.bold())
                        
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .foregroundColor(.primary)
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .background(BlurViewUI(style: .systemThinMaterial))
        .cornerRadius(15)
    }
    
}

struct MapUI_Previews: PreviewProvider {
    static var previews: some View {
        
        MapUI(travelTime: 0.00, distance: 0.00).preferredColorScheme(.dark)
    }
}

//extension MKMapType {
//    var name: String {
//        switch self {
//        case .standard:
//            return "Map"
//        case .hybrid:
//            return "Hybrid"
//        case .satellite:
//            return "Satellite"
//        default:
//            return "Other"
//        }
//    }
//}
