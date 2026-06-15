//
//  BottomSheetUI.swift
//  TheLightUI
//

import SDWebImageSwiftUI
import SwiftUI

struct BottomSheetUI: View {
    private struct Favorite: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let color: Color
    }

    @StateObject private var vm = MainMessagesViewModel()
    @ObservedObject var locationManager: LocationManager
    @Binding var offset: CGFloat
    var value: CGFloat
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Environment(\.openURL) private var openURL

    @State private var selection = 0

    private let metersPerMile: Double = 1609.344
    private let favorites = [
        Favorite(title: "Home", systemImage: "house.fill", color: .blue),
        Favorite(title: "Work", systemImage: "briefcase.fill", color: .gray),
        Favorite(title: "Add", systemImage: "mappin", color: .pink)
    ]

    private var isExpanded: Bool { offset <= value + 2 }
    private var handleScale: CGFloat { isExpanded ? 1.0 : 0.9 }

    private var speedText: String {
        let metersPerSecond = max(locationManager.location?.speed ?? 0.0, 0.0)
        let speed = 2.23694 * metersPerSecond
        return String(format: "Speed: %.0f", speed)
    }

    private var courseText: String {
        let course = max(locationManager.location?.course ?? 0.0, 0.0)
        return String(format: "Course: %.0f", course)
    }

    private var locationRows: [String] {
        [
            String(format: "Altitude: %.0f", locationManager.location?.altitude ?? 0),
            courseText,
            String(format: "Latitude: %.6f", locationManager.location?.coordinate.latitude ?? 0),
            String(format: "Longitude: %.6f", locationManager.location?.coordinate.longitude ?? 0),
            speedText
        ]
    }

    private var addressText: String {
        "\(locationManager.currentPlacemark?.subThoroughfare ?? "No Address") \(locationManager.currentPlacemark?.thoroughfare ?? "")\n\(locationManager.currentPlacemark?.locality ?? "") \(locationManager.currentPlacemark?.administrativeArea ?? "") \(locationManager.currentPlacemark?.postalCode ?? "")\n\(locationManager.currentPlacemark?.country ?? "")"
    }

    private var shareText: String {
        let coord = locationManager.location?.coordinate
        let lat = coord?.latitude ?? 0
        let lon = coord?.longitude ?? 0
        let niceAddress = addressText.replacingOccurrences(of: "\n", with: ", ")
        return "I'm here: \(niceAddress) (\(String(format: "%.5f", lat)), \(String(format: "%.5f", lon)))"
    }

    private var mapsURL: URL? {
        let coord = locationManager.location?.coordinate
        guard let lat = coord?.latitude, let lon = coord?.longitude else { return nil }
        return URL(string: "http://maps.apple.com/?ll=\(lat),\(lon)")
    }

    var body: some View {
        VStack {
            dragHandle
            routeSummary
            sheetContent
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .task { await vm.fetchCurrentUser() }
    }

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
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(String(format: "%0.0f min", travelTime / 60), systemImage: "clock")
                    Label(String(format: "%0.1f mi", distance / metersPerMile), systemImage: "map")
                        
                }
                .font(.caption)
                .foregroundColor(.primary)
            }

            Spacer()
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

    private var profileImage: some View {
        ProfileAvatarImage(urlString: vm.chatUser?.profileImageUrl)
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
            .modifier(OnChangeCompat(selection: $selection))
            .padding(.horizontal)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if selection == 0 {
                        favoritesSection
                        locationSummaryCard
                    } else {
                        locationSection
                    }
                }
                .padding(.top, 6)
                .foregroundColor(.primary)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.18), Color.black.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                .allowsHitTesting(false)
            }
        }
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
                    UIPasteboard.general.string = shareText + " \n" + mapsURL.absoluteString
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
    }

    private var callDestinationButton: some View {
        Button {
            openURL.callPhoneNumber("")
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
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)

            Text("Location Data")
                .font(.headline.bold())
                .foregroundColor(Color("AccentColor"))
                .padding(.horizontal)
                .padding(.top, 8)

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
            Button { } label: {
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

            Text(favorite.title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func iconForRow(_ row: String) -> String {
        if row.contains("Altitude") { return "arrow.up.and.down.circle" }
        if row.contains("Course") { return "location.north.line" }
        if row.contains("Latitude") { return "location.north" }
        if row.contains("Longitude") { return "location" }
        if row.contains("Speed") { return "gauge.medium" }
        return "info.circle"
    }
}

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
