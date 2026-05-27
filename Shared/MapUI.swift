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

// High-level Map UI composed of a SwiftUI shell and an MKMapView bridge for routing and a bottom sheet.

// MARK: - Map Screen
struct MapUI: View {
    // Location + Map state drives MKMapView and bottom sheet
    @StateObject private var manager = LocationManager()
    // Turn-by-turn instructions derived from MKRoute
    @State private var directions: [String] = []
    // Bottom sheet drag offset (0 collapsed, negative when expanded)
    @State private var offset: CGFloat = 0
    // Set when the user drags the map so we can show a recenter button
    @State private var isDragged = false
    // Destination address components used to geocode and request directions
    @State private var mapstreet = "5121 Lakefront Blvd Apt D"
    @State private var mapcity = "Delray Beach"
    @State private var mapstate = "Fl"
    @State private var mapzip = "33484"

    // Route ETA in seconds (bound to route summary)
    @State var travelTime: Double
    // Route distance in meters
    @State var distance: Double

    // Allow external initialization with default destination and initial route metrics
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
        // Layered layout: map at back, controls on top, draggable bottom sheet
        ZStack(alignment: .top) {
            mapLayer
            MapButtonView(manager: manager, directions: $directions)
            bottomSheetLayer
        }
        .onAppear {
            manager.startUpdating() // Start continuous location updates
        }
        .onDisappear {
            manager.stopUpdating() // Conserve battery when this screen leaves
        }
    }

    private var mapLayer: some View {
        // UIKit bridge for MKMapView; passes bindings for live updates
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
        .overlay(recenterButton, alignment: .center) // Appears when user pans the map
    }

    private var mapDragGesture: some Gesture {
        // Stop following the user when they manually pan/zoom
        DragGesture()
            .onChanged { _ in
                isDragged = true
                manager.stopUpdating() // Prevent auto recenters while dragging
            }
    }

    @ViewBuilder
    private var recenterButton: some View {
        // One-tap to re-center on current location and resume updates
        if isDragged {
            LocationButton(.shareCurrentLocation) {
                manager.requestLocation()
                manager.stopUpdating()
                isDragged = false // Hide the button again
                manager.startUpdating()
            }
            .padding()
        }
    }

    private var bottomSheetLayer: some View {
        // Draggable bottom sheet anchored to the bottom of the screen
        GeometryReader { reader in
            VStack {
                BottomSheetUI(
                    locationManager: manager,
                    offset: $offset,
                    value: expandedOffset(for: reader),
                    travelTime: $travelTime,
                    distance: $distance
                )
                // Initial position near bottom; additional offset applied by drag
                .offset(y: reader.frame(in: .global).height - 60)
                .offset(y: offset)
                .gesture(bottomSheetDragGesture(reader: reader))
            }
        }
    }

    private func bottomSheetDragGesture(reader: GeometryProxy) -> some Gesture {
        // Follow the finger with a springy feel
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.86, blendDuration: 0.2)) {
                    updateBottomSheetOffset(value: value, reader: reader)
                }
            }
            // Snap to expanded or collapsed based on drag
            .onEnded { value in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82, blendDuration: 0.2)) {
                    settleBottomSheet(value: value, reader: reader)
                }
                impact(.light) // Haptic confirmation
            }
    }

    // Compute live offset while dragging; supports expanding and collapsing depending on start zone
    private func updateBottomSheetOffset(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader) // Negative value placing sheet near full height
        let dragStartedLow = value.startLocation.y > reader.frame(in: .global).midY
        let dragStartedHigh = value.startLocation.y < reader.frame(in: .global).midY

        if dragStartedLow, value.translation.height < 0, offset > expandedOffset {
            offset = value.translation.height
        }

        if dragStartedHigh, value.translation.height > 0, offset < 0 {
            offset = expandedOffset + value.translation.height
        }
    }

    // Decide final resting position after drag ends
    private func settleBottomSheet(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader)
        let midpoint = reader.frame(in: .global).midY // Use screen midpoint as threshold
        let dragStartedLow = value.startLocation.y > midpoint
        let dragStartedHigh = value.startLocation.y < midpoint

        if dragStartedLow {
            offset = -value.translation.height > midpoint ? expandedOffset : 0
        }

        if dragStartedHigh {
            offset = value.translation.height < midpoint ? expandedOffset : 0
        }
    }

    // How far up the sheet moves when expanded (leaves top inset)
    private func expandedOffset(for reader: GeometryProxy) -> CGFloat {
        -reader.frame(in: .global).height + 150 // Expand to near full height leaving header visible
    }
    
    // Small convenience for haptic feedback
    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - MKMapView Bridge
struct MapView: UIViewRepresentable {
    // Bridge SwiftUI <-> MKMapView and manage directions rendering
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

    // Coordinator holds geocoder/directions and acts as MKMapViewDelegate
    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        // Reuse the single MKMapView managed by LocationManager
        let mapView = manager.mapView
        mapView.delegate = context.coordinator
        // Initial MKMapView configuration
        configure(mapView)
        // Kick off initial route calculation
        updateRoute(on: mapView, context: context)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Keep map type in sync with user toggle
        uiView.mapType = mapType
        // Only animate region if it truly changed
        updateRegionIfNeeded(on: uiView)
        // Recalculate route if inputs changed
        updateRoute(on: uiView, context: context)
    }

    // Toggle standard map settings and user tracking
    private func configure(_ mapView: MKMapView) {
        mapView.mapType = mapType
        mapView.pointOfInterestFilter = .init(including: [.evCharger, .gasStation])
        mapView.showsBuildings = false
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.userTrackingMode = .follow // Follow user's heading/position
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true // Blue dot
    }

    // Avoid unnecessary setRegion calls to prevent jitter
    private func updateRegionIfNeeded(on mapView: MKMapView) {
        guard CLLocationCoordinate2DIsValid(region.center) else { return } // Ensure region is valid
        guard mapView.region.center.latitude != region.center.latitude || mapView.region.center.longitude != region.center.longitude else { return } // Only update when center actually differs
        mapView.setRegion(region, animated: true)
    }

    // Calculate a directions route from current location to destination address
    private func updateRoute(on mapView: MKMapView, context: Context) {
        guard let userLocation = manager.location else { return } // Need a starting point

        let address = "\(mapstreet) \(mapcity), \(mapstate) \(mapzip)"
        let routeKey = "\(address)-\(userLocation.coordinate.latitude)-\(userLocation.coordinate.longitude)" // Memoization key to avoid duplicate work
        guard context.coordinator.routeKey != routeKey else { return } // Skip if nothing changed
        context.coordinator.routeKey = routeKey

        // Cancel any in-flight geocoding or directions
        context.coordinator.geocoder.cancelGeocode() // Cancel previous geocoding
        context.coordinator.currentDirections?.cancel() // Cancel previous directions

        let endPoint = "\(mapstreet), \(mapcity)"

        // Geocode destination then request MKDirections
        context.coordinator.geocoder.geocodeAddressString(address) { placemarks, _ in
            guard context.coordinator.routeKey == routeKey else { return }
            guard let location = placemarks?.first?.location else { return }

            DispatchQueue.main.async {
                // Build pins and directions request
                let sourceCoordinate = MKPlacemark(coordinate: userLocation.coordinate)
                let destinationCoordinate = MKPlacemark(coordinate: location.coordinate)
                let sourcePin = makeAnnotation(coordinate: sourceCoordinate.coordinate, title: "Start", subtitle: "Current Location")
                let destPin = makeAnnotation(coordinate: destinationCoordinate.coordinate, title: "Destination", subtitle: endPoint)
                let request = makeDirectionsRequest(source: sourceCoordinate, destination: destinationCoordinate)

                let mkDirections = MKDirections(request: request)
                context.coordinator.currentDirections = mkDirections

                mkDirections.calculate { response, _ in
                    // Take the best route
                    guard context.coordinator.routeKey == routeKey else { return }
                    guard let route = response?.routes.first else { return }

                    DispatchQueue.main.async {
                        travelTime = route.expectedTravelTime // seconds
                        distance = route.distance // meters
                        directions = route.steps.map(\.instructions).filter { !$0.isEmpty } // human-readable steps
                        // Render polyline and fit map
                        draw(route: route, sourcePin: sourcePin, destPin: destPin, on: mapView)
                    }
                }
            }
        }
    }

    // Convenience to build MKPointAnnotation
    private func makeAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }

    // Configure a basic automobile directions request
    private func makeDirectionsRequest(source: MKPlacemark, destination: MKPlacemark) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile // Driving directions
        return request
    }

    // Clear previous overlays/annotations, add new, and zoom to fit
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
        // Tracks the last inputs used to compute a route
        var routeKey: String?
        // Shared geocoder instance
        let geocoder = CLGeocoder()
        // Keep reference to cancel in-flight calculations
        var currentDirections: MKDirections?

        // Style the route polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.blue) // Route color
            renderer.lineWidth = 6 // Thickness
            renderer.lineCap = .round // Rounded ends
            return renderer
        }
    }
}

// MARK: - Map Controls
// On-map controls: dismiss, map type, location, and directions list
struct MapButtonView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var manager: LocationManager
    @State private var showDirections = false
    @Binding var directions: [String]
    @Environment(\.openURL) private var openURL

    // Convert m/s to mph for display
    private var speedText: String {
        let speed = 2.23694 * (manager.location?.speed ?? 0.0)
        return String(format: "Speed: %.0f", speed) // Whole mph
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
        // Present turn-by-turn text steps
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

    // Dismiss using a tappable avatar (custom image asset)
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

    // Show sheet with textual instructions
    private var directionsButton: some View {
        Button {
            showDirections.toggle()
        } label: {
            circularIcon("mappin.and.ellipse")
        }
    }

    // Toggle between .standard and .hybrid via manager
    private var mapTypeButton: some View {
        Button {
            manager.updateMapType()
        } label: {
            circularIcon(manager.mapType == .standard ? "network" : "map") // Swap icon based on current type
        }
    }

    // Request a one-shot location update
    private var locationButton: some View {
        LocationButton {
            manager.requestLocation()
        }
        .labelStyle(.iconOnly) // Hide text label
        .tint(.white)
        .clipShape(Circle())
        .background(
            Circle().fill(.thinMaterial)
        )
        .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
    }

    // Floating speed readout
    private var speedBadge: some View {
        VStack {
            Text(speedText)
                .foregroundColor(.primary)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 120, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
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
                .foregroundColor(.black)

            Divider()
                .background(Color.secondary)

            // Map each MKRoute step to a row with an icon
            List(directions.indices, id: \.self) { index in
                HStack {
                    // Simple heuristic to choose an icon
                    Image(systemName: directionsIcon(directions[index]))
                    Text(directions[index])
                        .padding()
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
    }

    // Reusable circular background + border for SF Symbols
    private func circularIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .modifier(CircularIconStyle())
    }

    private struct CircularIconStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.title2)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
    }

    // Very basic keyword matching for instruction icons
    private func directionsIcon(_ instruction: String) -> String {
        if instruction.contains("destination") {
            return "mappin.circle.fill" // Arrived
        } else if instruction.contains("right") {
            return "arrow.turn.up.right" // Right turn
        } else if instruction.contains("left") {
            return "arrow.turn.up.left" // Left turn
        } else {
            return "arrow.up" // Continue straight
        }
    }
}

// MARK: - Bottom Sheet
struct BottomSheetUI: View {
    // Simple model for favorite destinations
    private struct Favorite: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let color: Color
    }

    // Used only to fetch profile image URL
    @State private var vm = MainMessagesViewModel()
    @ObservedObject var locationManager: LocationManager
    // Shared with parent to control expansion
    @Binding var offset: CGFloat
    // The expanded offset threshold
    var value: CGFloat
    // Bound to route metrics from MapView
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Environment(\.openURL) private var openURL
    
    // Segmented control index (0: Overview, 1: Details)
    @State private var selection: Int = 0
    
    // Whether the sheet is near its expanded position
    private var isExpanded: Bool { offset <= value + 2 }
    // Slight scale effect on the grabber when expanded
    private var handleScale: CGFloat { isExpanded ? 1.0 : 0.9 }

    // Demo favorites shown horizontally
    private let favorites = [
        Favorite(title: "Home", systemImage: "house.fill", color: .blue),
        Favorite(title: "Work", systemImage: "briefcase.fill", color: .gray),
        Favorite(title: "Add", systemImage: "mappin", color: .pink)
    ]

    // Unit conversion for distance display
    private let metersPerMile: Double = 1609.344

    // Local speed readout (mph)
    private var speedText: String {
        let speed = 2.23694 * (locationManager.location?.speed ?? 0.0)
        return String(format: "Speed: %.0f", speed)
    }

    // Snapshot of core CLLocation fields for the Details tab
    private var locationRows: [String] {
        [
            String(format: "Altitude: %.0f", locationManager.location?.altitude ?? 0),
            speedText,
            String(format: "Latitude: %.0f", locationManager.location?.coordinate.latitude ?? 0),
            String(format: "Longitude: %.0f", locationManager.location?.coordinate.longitude ?? 0),
            String(format: "Course: %.0f", locationManager.location?.course ?? 0)
        ]
    }

    // Multiline reverse-geocoded address
    private var addressText: String {
        "\(locationManager.currentPlacemark?.subThoroughfare ?? "No Address") \(locationManager.currentPlacemark?.thoroughfare ?? "")\n\(locationManager.currentPlacemark?.locality ?? "") \(locationManager.currentPlacemark?.administrativeArea ?? "") \(locationManager.currentPlacemark?.postalCode ?? "")\n\(locationManager.currentPlacemark?.country ?? "")"
    }
    
    // Fallback formatted text for sharing on older iOS
    private var shareText: String {
        let coord = locationManager.location?.coordinate
        let lat = coord?.latitude ?? 0
        let lon = coord?.longitude ?? 0
        let niceAddress = addressText.replacingOccurrences(of: "\n", with: ", ")
        return "I'm here: \(niceAddress) (\(String(format: "%.5f", lat)), \(String(format: "%.5f", lon)))"
    }

    // Apple Maps deep link to current coordinate
    private var mapsURL: URL? {
        let coord = locationManager.location?.coordinate
        guard let lat = coord?.latitude, let lon = coord?.longitude else { return nil }
        // Apple Maps URL that opens the coordinate
        return URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)")
    }

    var body: some View {
        VStack {
            // Grabber
            dragHandle
            // Compact card with ETA and distance
            routeSummary
            // Segmented content: Favorites + Summary or raw details
            sheetContent
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    // Visual handle indicating the view is draggable
    private var dragHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .scaleEffect(x: handleScale, y: 1.0, anchor: .center)
            .animation(.easeInOut(duration: 0.2), value: handleScale)
            .padding(.top, 8)
    }

    private var routeSummary: some View {
        HStack(spacing: 12) {
            // Leading circular icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Image(systemName: "bolt.car.fill")
                    .foregroundStyle(.blue)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Trip Summary")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Label(String(format: "%0.0f min", travelTime / 60), systemImage: "clock")
                    Label(String(format: "%0.1f mi", distance / metersPerMile), systemImage: "map")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Trailing profile image loaded from URL
            profileImage
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // Remote avatar using SDWebImageSwiftUI
    private var profileImage: some View {
        WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(radius: 2)
    }
    
    // iOS 16/17-compatible onChange overload to trigger haptics on Picker changes
    private struct OnChangeCompat: ViewModifier {
        @Binding var selection: Int
        func body(content: Content) -> some View {
            if #available(iOS 17.0, *) {
                content.onChange(of: selection) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                content.onChange(of: selection) { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }
    
    private var sheetContent: some View {
        VStack(spacing: 8) {
            // Switch between Overview and Details
            Picker("", selection: $selection) {
                Text("Overview").tag(0)
                Text("Details").tag(1)
            }
            .pickerStyle(.segmented)
            .modifier(
                OnChangeCompat(selection: $selection)
            )
            .padding(.horizontal)

            // Content varies by selection
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Overview
                    if selection == 0 {
                        favoritesSection
                        locationSummaryCard
                    } else {
                        // Details
                        locationSection
                    }
                }
                .padding(.top, 6)
                .foregroundColor(.primary)
            }
            .overlay(
                LinearGradient(colors: [Color.black.opacity(0.18), Color.black.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 10)
                    .allowsHitTesting(false), alignment: .top
            )
        }
    }

    private var locationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.red)
                Text("Current Location")
                    .font(.headline)
                Spacer()
                // Share button uses ShareLink on iOS 16+, copies text otherwise
                if let mapsURL = mapsURL {
                    if #available(iOS 16.0, *) {
                        ShareLink(item: mapsURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Share your location")
                    } else {
                        Button {
                            UIPasteboard.general.string = shareText + " \n" + mapsURL.absoluteString // Copy share text + link
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.headline)
                                .padding(8)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy your location")
                    }
                }
                Button {
                    openURL.callPhoneNumber("+15615551234")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.headline)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Call destination")
            }
            .padding(.bottom, 2)

            Text(addressText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(nil)

            Divider().opacity(0.2)

            HStack(spacing: 16) {
                Label(speedText, systemImage: "gauge.medium")
                Label(String(format: "Alt %.0fft", locationManager.location?.altitude ?? 0), systemImage: "arrow.up.and.down.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Favorites")
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
                .padding()

            // Horizontal list of quick targets
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
            // Current address
            Text(addressText)
                .padding()
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)

            // Raw sensor values
            Text("Location Data")
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
                .padding(.horizontal)
                .padding(.top, 8)

            // Each row shows one numeric field
            ForEach(locationRows, id: \.self) { row in
                HStack(spacing: 12) {
                    Image(systemName: iconForRow(row))
                        .foregroundStyle(.blue)
                    Text(row)
                        .lineLimit(1)
                        .font(.callout)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Spacer(minLength: 8)
        }
    }

    private func favoriteButton(_ favorite: Favorite) -> some View {
        VStack(spacing: 8) {
            // Placeholder action for favorite selection
            Button {} label: {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
                    Image(systemName: favorite.systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(favorite.color)
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)

            // Label under the icon
            Text(favorite.title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // Choose SF Symbol based on the row's label
    private func iconForRow(_ row: String) -> String {
        if row.contains("Altitude") { return "arrow.up.and.down.circle" }
        if row.contains("Speed") { return "gauge.medium" }
        if row.contains("Latitude") { return "location.north" }
        if row.contains("Longitude") { return "location" }
        if row.contains("Course") { return "location.north.line" }
        return "info.circle"
    }

}
  
// MARK: - Preview
struct MapUI_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with zeroed metrics
        MapUI(travelTime: 0.00, distance: 0.00)
            .preferredColorScheme(.dark)
    }
}

