//
//  BottomSheetUI.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetUI: View {
    var locationManager: LocationManager
    let profileImageURL: String?
    let destination: MapDestination?
    @Binding var travelTime: Double
    @Binding var distance: Double
    var onRouteToAddress: ((MapDestination) -> Void)? = nil

    @State private var selection = 0
    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat?

    private let favorites: [BottomSheetFavorite] = [
        BottomSheetFavorite(title: "Home", systemImage: "house.fill", color: .blue),
        BottomSheetFavorite(title: "Work", systemImage: "briefcase.fill", color: .gray),
        BottomSheetFavorite(title: "Add", systemImage: "mappin", color: .pink)
    ]

    // iPad's bottom safe-area inset is smaller than iPhone's, so peek the
    // collapsed bar a little higher there to keep it easy to grab.
    private var collapsedVisibleHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 80 : 16
    }
    private let minimumExpandedTopInset: CGFloat = 150
    private let halfExpandedBottomInset: CGFloat = 60
    private let safeAreaSpacing: CGFloat = 12

    private var speedText: String {
        MapFormat.speed(locationManager.location?.speed ?? 0)
    }

    private var altitudeText: String {
        Measurement(value: locationManager.location?.altitude ?? 0, unit: UnitLength.meters)
            .converted(to: .feet)
            .formatted(
                .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(0))
                )
            )
    }

    private var distanceText: String {
        Measurement(value: distance, unit: UnitLength.meters)
            .converted(to: .miles)
            .formatted(
                .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.precision(.fractionLength(1))
                )
            )
    }

    private var travelTimeText: String {
        Duration.seconds(max(travelTime, 0))
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    private var locationRows: [BottomSheetLocationInfoRow] {
        let coordinate = locationManager.location?.coordinate
        return [
            BottomSheetLocationInfoRow(
                id: "altitude",
                title: "Altitude",
                value: altitudeText,
                systemImage: "arrow.up.and.down.circle"
            ),
            BottomSheetLocationInfoRow(
                id: "course",
                title: "Course",
                value: String(format: "%.0f°", max(locationManager.location?.course ?? 0.0, 0.0)),
                systemImage: "location.north.line"
            ),
            BottomSheetLocationInfoRow(
                id: "latitude",
                title: "Latitude",
                value: String(format: "%.6f", coordinate?.latitude ?? 0),
                systemImage: "location.north"
            ),
            BottomSheetLocationInfoRow(
                id: "longitude",
                title: "Longitude",
                value: String(format: "%.6f", coordinate?.longitude ?? 0),
                systemImage: "location"
            ),
            BottomSheetLocationInfoRow(
                id: "speed",
                title: "Speed",
                value: speedText,
                systemImage: "gauge.medium"
            )
        ]
    }

    private var currentAddressText: String {
        let placemark = locationManager.currentPlacemark
        let line1 = "\(placemark?.subThoroughfare ?? "No Address") \(placemark?.thoroughfare ?? "")"
        let line2 = "\(placemark?.locality ?? "") \(placemark?.administrativeArea ?? "") \(placemark?.postalCode ?? "")"
        let line3 = placemark?.country ?? ""
        return "\(line1)\n\(line2)\n\(line3)"
    }

    private var destinationAddressText: String {
        guard let destination else { return currentAddressText }
        return "\(destination.street)\n\(destination.city) \(destination.state) \(destination.zip)"
    }

    private var mapsURL: URL? {
        let coord = locationManager.location?.coordinate
        guard let lat = coord?.latitude, let lon = coord?.longitude else { return nil }
        return URL(string: "https://maps.apple.com/?ll=\(lat),\(lon)")
    }

    private var destinationMapsURL: URL? {
        guard
            let destination,
            let encodedAddress = destination.address
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "https://maps.apple.com/?address=\(encodedAddress)")
    }

    var body: some View {
        GeometryReader { reader in
            VStack {
                sheetBody(reader: reader)
                    .offset(y: collapsedYPosition(for: reader))
                    .offset(y: offset)
                    .gesture(bottomSheetDragGesture(reader: reader))
            }
        }
    }

    private func sheetBody(reader: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            dragHandle(reader: reader)
            BottomSheetRouteSummaryView(
                travelTimeText: travelTimeText,
                distanceText: distanceText,
                profileImageURL: profileImageURL
            )
            BottomSheetContentView(
                selection: $selection,
                favorites: favorites,
                currentAddressText: currentAddressText,
                speedText: speedText,
                altitudeText: altitudeText,
                mapsURL: mapsURL,
                destinationAddressText: destinationAddressText,
                locationRows: locationRows,
                destinationMapsURL: destinationMapsURL,
                onSelectionChange: { impact(.light) },
                onFavoriteRoute: { destination in
                    onRouteToAddress?(destination)
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88, blendDuration: 0.12)) {
                        offset = collapsedOffset
                    }
                }
            )
        }
        .padding(.top, 2)
        .background(sheetBackgroundColor(reader: reader))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: -2)
        .animation(.easeInOut(duration: 0.2), value: isCollapsed(reader: reader))
    }

    private func sheetBackgroundColor(reader: GeometryProxy) -> Color {
        isCollapsed(reader: reader)
            ? Color(.systemGray5)
            : Color(.secondarySystemGroupedBackground)
    }

    private func dragHandle(reader: GeometryProxy) -> some View {
        let handleScale: CGFloat = isExpanded(reader: reader) ? 1.0 : 0.9
        return Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .scaleEffect(x: handleScale, y: 1.0, anchor: .center)
            .animation(.easeInOut(duration: 0.2), value: handleScale)
            .padding(.top, 8)
    }

    private func bottomSheetDragGesture(reader: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                updateOffset(value: value, reader: reader)
            }
            .onEnded { value in
                let startingOffset = dragStartOffset ?? offset
                let targetOffset = nearestOffset(
                    to: startingOffset + value.predictedEndTranslation.height,
                    reader: reader
                )
                dragStartOffset = nil
                withAnimation(.spring(response: 0.34, dampingFraction: 0.88, blendDuration: 0.12)) {
                    offset = targetOffset
                }
                impact(.light)
            }
    }

    private func updateOffset(value: DragGesture.Value, reader: GeometryProxy) {
        if dragStartOffset == nil {
            dragStartOffset = offset
        }
        let startingOffset = dragStartOffset ?? offset
        offset = clampedOffset(startingOffset + value.translation.height, reader: reader)
    }

    private func isExpanded(reader: GeometryProxy) -> Bool {
        offset <= expandedOffset(for: reader) + 2
    }

    private func isCollapsed(reader: GeometryProxy) -> Bool {
        offset >= collapsedOffset - 2
    }

    private func nearestOffset(to proposedOffset: CGFloat, reader: GeometryProxy) -> CGFloat {
        snapOffsets(for: reader)
            .min { abs($0 - proposedOffset) < abs($1 - proposedOffset) } ?? 0
    }

    private func clampedOffset(_ proposedOffset: CGFloat, reader: GeometryProxy) -> CGFloat {
        min(max(proposedOffset, expandedOffset(for: reader)), collapsedOffset)
    }

    private func snapOffsets(for reader: GeometryProxy) -> [CGFloat] {
        [expandedOffset(for: reader), halfExpandedOffset(for: reader), collapsedOffset]
    }

    private func expandedOffset(for reader: GeometryProxy) -> CGFloat {
        -reader.size.height + expandedTopInset(for: reader)
    }

    private func halfExpandedOffset(for reader: GeometryProxy) -> CGFloat {
        -(reader.size.height * 0.5) + halfExpandedBottomInset + reader.safeAreaInsets.bottom
    }

    private func collapsedYPosition(for reader: GeometryProxy) -> CGFloat {
        reader.size.height - collapsedVisibleHeight - reader.safeAreaInsets.bottom
    }

    private func expandedTopInset(for reader: GeometryProxy) -> CGFloat {
        max(minimumExpandedTopInset, reader.safeAreaInsets.top + safeAreaSpacing)
    }

    private var collapsedOffset: CGFloat { 0 }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
