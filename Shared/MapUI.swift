//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import MapKit
import CoreLocationUI
import SDWebImageSwiftUI

// MARK: - Map Screen
struct MapUI: View {
    @StateObject private var manager = LocationManager()
    @State private var directions: [String] = []
    @State private var offset: CGFloat = 0
    @State private var isDragged = false
    @State private var mapstreet = "5121 Lakefront Blvd Apt D"
    @State private var mapcity = "Delray Beach"
    @State private var mapstate = "Fl"
    @State private var mapzip = "33484"

    @State var travelTime: Double
    @State var distance: Double

    init(
        mapstreet: String = "5121 Lakefront Blvd Apt D",
        mapcity: String = "Delray Beach",
        mapstate: String = "Fl",
        mapzip: String = "33484",
        travelTime: Double,
        distance: Double
    ) {
        self._mapstreet = State(initialValue: mapstreet)
        self._mapcity = State(initialValue: mapcity)
        self._mapstate = State(initialValue: mapstate)
        self._mapzip = State(initialValue: mapzip)
        self._travelTime = State(initialValue: travelTime)
        self._distance = State(initialValue: distance)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            MapButtonView(manager: manager, directions: $directions)
            bottomSheetLayer
        }
        .onAppear {
            manager.startUpdating()
        }
        .onDisappear {
            manager.stopUpdating()
        }
    }

    private var mapLayer: some View {
        MapView(
            manager: manager,
            travelTime: $travelTime,
            distance: $distance,
            directions: $directions,
            mapstreet: $mapstreet,
            mapcity: $mapcity,
            mapstate: $mapstate,
            mapzip: $mapzip,
            region: $manager.region,
            mapType: manager.mapType
        )
        .ignoresSafeArea(.all, edges: .all)
        .gesture(mapDragGesture)
        .overlay(recenterButton, alignment: .center)
    }

    private var mapDragGesture: some Gesture {
        DragGesture()
            .onChanged { _ in
                isDragged = true
                manager.stopUpdating()
            }
    }

    @ViewBuilder
    private var recenterButton: some View {
        if isDragged {
            LocationButton(.shareCurrentLocation) {
                manager.requestLocation()
                manager.stopUpdating()
                isDragged = false
                manager.startUpdating()
            }
            .padding()
        }
    }

    private var bottomSheetLayer: some View {
        GeometryReader { reader in
            VStack {
                BottomSheetUI(
                    locationManager: manager,
                    offset: $offset,
                    value: expandedOffset(for: reader),
                    travelTime: $travelTime,
                    distance: $distance
                )
                .offset(y: reader.frame(in: .global).height - 60)
                .offset(y: offset)
                .gesture(bottomSheetDragGesture(reader: reader))
            }
        }
    }

    private func bottomSheetDragGesture(reader: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation {
                    updateBottomSheetOffset(value: value, reader: reader)
                }
            }
            .onEnded { value in
                withAnimation {
                    settleBottomSheet(value: value, reader: reader)
                }
            }
    }

    private func updateBottomSheetOffset(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader)
        let dragStartedLow = value.startLocation.y > reader.frame(in: .global).midY
        let dragStartedHigh = value.startLocation.y < reader.frame(in: .global).midY

        if dragStartedLow, value.translation.height < 0, offset > expandedOffset {
            offset = value.translation.height
        }

        if dragStartedHigh, value.translation.height > 0, offset < 0 {
            offset = expandedOffset + value.translation.height
        }
    }

    private func settleBottomSheet(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader)
        let midpoint = reader.frame(in: .global).midY
        let dragStartedLow = value.startLocation.y > midpoint
        let dragStartedHigh = value.startLocation.y < midpoint

        if dragStartedLow {
            offset = -value.translation.height > midpoint ? expandedOffset : 0
        }

        if dragStartedHigh {
            offset = value.translation.height < midpoint ? expandedOffset : 0
        }
    }

    private func expandedOffset(for reader: GeometryProxy) -> CGFloat {
        -reader.frame(in: .global).height + 150
    }
}

// MARK: - MKMapView Bridge
struct MapView: UIViewRepresentable {
    @ObservedObject var manager: LocationManager
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var directions: [String]
    @Binding var mapstreet: String
    @Binding var mapcity: String
    @Binding var mapstate: String
    @Binding var mapzip: String
    @Binding var region: MKCoordinateRegion

    let mapType: MKMapType

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = manager.mapView
        mapView.delegate = context.coordinator
        configure(mapView)
        updateRoute(on: mapView, context: context)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.mapType = mapType
        updateRegionIfNeeded(on: uiView)
        updateRoute(on: uiView, context: context)
    }

    private func configure(_ mapView: MKMapView) {
        mapView.mapType = mapType
        mapView.pointOfInterestFilter = .init(including: [.evCharger, .gasStation])
        mapView.showsBuildings = false
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.userTrackingMode = .follow
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true
    }

    private func updateRegionIfNeeded(on mapView: MKMapView) {
        guard CLLocationCoordinate2DIsValid(region.center) else { return }
        guard mapView.region.center.latitude != region.center.latitude || mapView.region.center.longitude != region.center.longitude else { return }
        mapView.setRegion(region, animated: true)
    }

    private func updateRoute(on mapView: MKMapView, context: Context) {
        guard let userLocation = manager.location else { return }

        let address = "\(mapstreet) \(mapcity), \(mapstate) \(mapzip)"
        let routeKey = "\(address)-\(userLocation.coordinate.latitude)-\(userLocation.coordinate.longitude)"
        guard context.coordinator.routeKey != routeKey else { return }
        context.coordinator.routeKey = routeKey

        // Cancel any in-flight geocoding or directions
        context.coordinator.geocoder.cancelGeocode()
        context.coordinator.currentDirections?.cancel()

        let endPoint = "\(mapstreet), \(mapcity)"

        context.coordinator.geocoder.geocodeAddressString(address) { placemarks, _ in
            guard context.coordinator.routeKey == routeKey else { return }
            guard let location = placemarks?.first?.location else { return }

            DispatchQueue.main.async {
                let sourceCoordinate = MKPlacemark(coordinate: userLocation.coordinate)
                let destinationCoordinate = MKPlacemark(coordinate: location.coordinate)
                let sourcePin = makeAnnotation(coordinate: sourceCoordinate.coordinate, title: "Start", subtitle: "Current Location")
                let destPin = makeAnnotation(coordinate: destinationCoordinate.coordinate, title: "Destination", subtitle: endPoint)
                let request = makeDirectionsRequest(source: sourceCoordinate, destination: destinationCoordinate)

                let mkDirections = MKDirections(request: request)
                context.coordinator.currentDirections = mkDirections

                mkDirections.calculate { response, _ in
                    guard context.coordinator.routeKey == routeKey else { return }
                    guard let route = response?.routes.first else { return }

                    DispatchQueue.main.async {
                        travelTime = route.expectedTravelTime
                        distance = route.distance
                        directions = route.steps.map(\.instructions).filter { !$0.isEmpty }
                        draw(route: route, sourcePin: sourcePin, destPin: destPin, on: mapView)
                    }
                }
            }
        }
    }

    private func makeAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }

    private func makeDirectionsRequest(source: MKPlacemark, destination: MKPlacemark) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        return request
    }

    private func draw(route: MKRoute, sourcePin: MKPointAnnotation, destPin: MKPointAnnotation, on mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.addAnnotations([sourcePin, destPin])
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25),
            animated: true
        )
    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var routeKey: String?
        let geocoder = CLGeocoder()
        var currentDirections: MKDirections?

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.blue)
            renderer.lineWidth = 6
            renderer.lineCap = .round
            return renderer
        }
    }
}

// MARK: - Map Controls
struct MapButtonView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var manager: LocationManager
    @State private var showDirections = false
    @Binding var directions: [String]
    @Environment(\.openURL) private var openURL

    private var speedText: String {
        let speed = 2.23694 * (manager.location?.speed ?? 0.0)
        return String(format: "Speed: %.0f", speed)
    }

    var body: some View {
        HStack {
            leadingControls
            Spacer()
            speedBadge
            Spacer()
            trailingControls
        }
        .padding()
        .sheet(isPresented: $showDirections) {
            directionsSheet
        }
    }

    private var leadingControls: some View {
        VStack {
            dismissButton
            Spacer()
            directionsButton
                .padding(.bottom, 60)
        }
        .padding(.horizontal)
    }

    private var trailingControls: some View {
        VStack {
            mapTypeButton
            Spacer()
            locationButton
                .padding(.bottom, 60)
        }
        .padding(.horizontal)
    }

    private var dismissButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image("taylor_swift_profile")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.top, 2)
        }
    }

    private var directionsButton: some View {
        Button {
            showDirections.toggle()
        } label: {
            circularIcon("mappin.and.ellipse")
        }
    }

    private var mapTypeButton: some View {
        Button {
            manager.updateMapType()
        } label: {
            circularIcon(manager.mapType == .standard ? "network" : "map")
        }
    }

    private var locationButton: some View {
        LocationButton {
            manager.requestLocation()
        }
        .labelStyle(.iconOnly)
        .foregroundColor(.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private var speedBadge: some View {
        VStack {
            Text(speedText)
                .foregroundColor(.primary)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 120, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(Color.black)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 2)
                )
            Spacer()
        }
    }

    private var directionsSheet: some View {
        VStack(spacing: 0) {
            Text("Directions")
                .font(.largeTitle)
                .bold()
                .padding()

            Divider()
                .background(Color.secondary)

            List(directions.indices, id: \.self) { index in
                HStack {
                    Image(systemName: directionsIcon(directions[index]))
                    Text(directions[index])
                        .padding()
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
    }

    private func circularIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .modifier(CircularIconStyle())
    }

    private struct CircularIconStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.title2)
                .padding(10)
                .background(Color.secondary)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }

    private func directionsIcon(_ instruction: String) -> String {
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

// MARK: - Bottom Sheet
struct BottomSheetUI: View {
    private struct Favorite: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let color: Color
    }

    @State private var vm = MainMessagesViewModel()
    @ObservedObject var locationManager: LocationManager
    @Binding var offset: CGFloat
    var value: CGFloat
    @Binding var travelTime: Double
    @Binding var distance: Double

    private let favorites = [
        Favorite(title: "Home", systemImage: "house.fill", color: .blue),
        Favorite(title: "Work", systemImage: "briefcase.fill", color: .gray),
        Favorite(title: "Add", systemImage: "mappin", color: .pink)
    ]

    private let metersPerMile: Double = 1609.344

    private var speedText: String {
        let speed = 2.23694 * (locationManager.location?.speed ?? 0.0)
        return String(format: "Speed: %.0f", speed)
    }

    private var locationRows: [String] {
        [
            String(format: "Altitude: %.0f", locationManager.location?.altitude ?? 0),
            speedText,
            String(format: "Latitude: %.0f", locationManager.location?.coordinate.latitude ?? 0),
            String(format: "Longitude: %.0f", locationManager.location?.coordinate.longitude ?? 0),
            String(format: "Course: %.0f", locationManager.location?.course ?? 0)
        ]
    }

    private var addressText: String {
        "\(locationManager.currentPlacemark?.subThoroughfare ?? "No Address") \(locationManager.currentPlacemark?.thoroughfare ?? "")\n\(locationManager.currentPlacemark?.locality ?? "") \(locationManager.currentPlacemark?.administrativeArea ?? "") \(locationManager.currentPlacemark?.postalCode ?? "")\n\(locationManager.currentPlacemark?.country ?? "")"
    }

    var body: some View {
        VStack {
            dragHandle
            routeSummary
            sheetContent
        }
        .background(BlurViewUI(style: .systemThinMaterial))
        .cornerRadius(15)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 50, height: 5)
            .padding(.top, 7)
    }

    private var routeSummary: some View {
        HStack(spacing: 0) {
            Text("Go Online")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, -18)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .overlay(alignment: .trailing) {
                    profileImage
                }
                .overlay(alignment: .leading) {
                    tripStats
                }
        }
        .foregroundColor(.white)
        .cornerRadius(15)
    }

    private var profileImage: some View {
        WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
            .resizable()
            .scaledToFill()
            .frame(width: 45, height: 45)
            .clipShape(Circle())
            .clipped()
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .padding(.trailing, 20)
            .padding(.bottom, 14)
            .shadow(radius: 5)
    }

    private var tripStats: some View {
        VStack(alignment: .leading) {
            statRow(systemImage: "car", text: String(format: "%0.0f min", travelTime / 60))
            Spacer()
                .frame(minHeight: 8, idealHeight: 8, maxHeight: 8)
                .fixedSize()
            statRow(systemImage: "bolt.car.fill", text: String(format: "%0.0f miles", distance / metersPerMile))
                .padding(.bottom, 10)
        }
        .padding(.leading, 15)
        .foregroundColor(.white)
        .font(.caption.bold())
    }

    private var sheetContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                favoritesSection
                locationSection
            }
            .padding(.top, 10)
            .foregroundColor(.primary)
            .background(Color(UIColor.secondarySystemBackground))
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Favorites")
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
                .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(favorites) { favorite in
                        favoriteButton(favorite)
                    }
                }
            }
            .background(Color(UIColor.tertiarySystemGroupedBackground))
        }
    }

    private var locationSection: some View {
        Group {
            Text(addressText)
                .padding()
                .font(.callout.bold())

            Text("Location Data")
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
                .padding()

            ForEach(locationRows, id: \.self) { row in
                Text(row)
                    .padding()
                    .lineLimit(1)
                    .font(.callout.bold())
            }

            Spacer()
        }
    }

    private func favoriteButton(_ favorite: Favorite) -> some View {
        VStack {
            Button {} label: {
                Image(systemName: favorite.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding()
                    .background(favorite.color)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            Text(favorite.title)
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
        }
        .padding()
    }

    private func statRow(systemImage: String, text: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

// MARK: - Preview
struct MapUI_Previews: PreviewProvider {
    static var previews: some View {
        MapUI(travelTime: 0.00, distance: 0.00)
            .preferredColorScheme(.dark)
    }
}
