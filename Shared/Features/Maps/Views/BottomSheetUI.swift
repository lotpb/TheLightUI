//
//  BottomSheetUI.swift
//  TheLightUI
//

import SDWebImageSwiftUI
import SwiftUI

struct BottomSheetUI: View {
    private struct Favorite: Identifiable {
        var id: String { title }
        let title: String
        let systemImage: String
        let color: Color
    }

    private struct LocationInfoRow: Identifiable {
        let id: String
        let title: String
        let value: String
        let systemImage: String
    }

    var locationManager: LocationManager
    let profileImageURL: String?
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Environment(\.openURL) private var openURL

    @State private var selection = 0
    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat?

    private let favorites = [
        Favorite(title: "Home", systemImage: "house.fill", color: .blue),
        Favorite(title: "Work", systemImage: "briefcase.fill", color: .gray),
        Favorite(title: "Add", systemImage: "mappin", color: .pink)
    ]

    // iPad's bottom safe-area inset is smaller than iPhone's, so peek the
    // collapsed bar a little higher there to keep it easy to grab.
    private var collapsedVisibleHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 52 : 16
    }
    private let minimumExpandedTopInset: CGFloat = 150
    private let halfExpandedBottomInset: CGFloat = 60
    private let safeAreaSpacing: CGFloat = 12

    private var speedText: String {
        Measurement(value: max(locationManager.location?.speed ?? 0, 0), unit: UnitSpeed.metersPerSecond)
            .converted(to: .milesPerHour)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private var altitudeText: String {
        Measurement(value: locationManager.location?.altitude ?? 0, unit: UnitLength.meters)
            .converted(to: .feet)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private var distanceText: String {
        Measurement(value: distance, unit: UnitLength.meters)
            .converted(to: .miles)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1))))
    }

    private var travelTimeText: String {
        Duration.seconds(max(travelTime, 0))
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    private var locationRows: [LocationInfoRow] {
        let coordinate = locationManager.location?.coordinate

        return [
            LocationInfoRow(
                id: "altitude",
                title: "Altitude",
                value: altitudeText,
                systemImage: "arrow.up.and.down.circle"
            ),
            LocationInfoRow(
                id: "course",
                title: "Course",
                value: String(format: "%.0f°", max(locationManager.location?.course ?? 0.0, 0.0)),
                systemImage: "location.north.line"
            ),
            LocationInfoRow(
                id: "latitude",
                title: "Latitude",
                value: String(format: "%.6f", coordinate?.latitude ?? 0),
                systemImage: "location.north"
            ),
            LocationInfoRow(
                id: "longitude",
                title: "Longitude",
                value: String(format: "%.6f", coordinate?.longitude ?? 0),
                systemImage: "location"
            ),
            LocationInfoRow(
                id: "speed",
                title: "Speed",
                value: speedText,
                systemImage: "gauge.medium"
            )
        ]
    }

    private var addressText: String {
        "\(locationManager.currentPlacemark?.subThoroughfare ?? "No Address") \(locationManager.currentPlacemark?.thoroughfare ?? "")\n\(locationManager.currentPlacemark?.locality ?? "") \(locationManager.currentPlacemark?.administrativeArea ?? "") \(locationManager.currentPlacemark?.postalCode ?? "")\n\(locationManager.currentPlacemark?.country ?? "")"
    }

    private var mapsURL: URL? {
        let coord = locationManager.location?.coordinate
        guard let lat = coord?.latitude, let lon = coord?.longitude else { return nil }
        return URL(string: "https://maps.apple.com/?ll=\(lat),\(lon)")
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
            routeSummary
            sheetContent
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

    private var routeSummary: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.14))
                Image(systemName: "car.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text("Trip Summary")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 14) {
                    Label(travelTimeText, systemImage: "clock")
                    Label(distanceText, systemImage: "map")
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.primary)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
            }

            Spacer()
            profileImage
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private var profileImage: some View {
        ProfileAvatarImage(urlString: profileImageURL)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(radius: 2)
    }

    private var sheetContent: some View {
        VStack(spacing: 8) {
            Picker("", selection: $selection) {
                Text("Overview").tag(0)
                Text("Details").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: selection) { _, _ in
                impact(.light)
            }
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if selection == 0 {
                        favoritesSection
                        locationSummaryCard
                    } else {
                        locationSection
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 12)
                .foregroundStyle(Color.primary)
            }
        }
        // Cap the content width and center it on wide iPad layouts; the sheet
        // background still spans the full width.
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    private var locationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            locationSummaryHeader

            Text(addressText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(nil)

            Divider().opacity(0.2)

            HStack(spacing: 16) {
                Label(speedText, systemImage: "gauge.medium")
                Label(altitudeText, systemImage: "arrow.up.and.down.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var locationSummaryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.red)
            Text("Current Location")
                .font(.headline)
            Spacer()
            shareLocationButton
            callDestinationButton
        }
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private var shareLocationButton: some View {
        if let mapsURL {
            ShareLink(item: mapsURL) {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share your location")
        }
    }

    private var callDestinationButton: some View {
        Button {
            openURL.callPhoneNumber("")
            impact(.light)
        } label: {
            Image(systemName: "phone.fill")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemBackground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Call destination")
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Favorites")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(favorites) { favorite in
                        favoriteButton(favorite)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var locationSection: some View {
        Group {
            Text(addressText)
                .padding()
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
                .padding(.horizontal)

            Text("Location Data")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            let columns = [
                GridItem(.flexible(), spacing: 30),
                GridItem(.flexible(), spacing: 30)
            ]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(locationRows) { row in
                    HStack(spacing: 12) {
                        Image(systemName: row.systemImage)
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(row.title)
                                .font(.callout)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            
                            Text(row.value)
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(.white.opacity(0.52), lineWidth: 1)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
            Spacer(minLength: 8)
        }
    }

    private func favoriteButton(_ favorite: Favorite) -> some View {
        VStack(spacing: 8) {
            Button { } label: {
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                    Image(systemName: favorite.systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(favorite.color)
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)

            Text(favorite.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

}
