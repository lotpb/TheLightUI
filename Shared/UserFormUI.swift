//
//  UserFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 4/30/21.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct UserFormUI: View {
    @StateObject private var viewModel = MainMessagesViewModel()

    @State private var storedLatitude = ""
    @State private var storedLongitude = ""
    @State private var storedFirstName = ""
    @State private var storedLastName = ""
    @State private var storedPhone = ""

    // Parse stored latitude/longitude with sensible defaults.
    private var latitudeValue: Double {
        Double(storedLatitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 26.465019
    }
    private var longitudeValue: Double {
        Double(storedLongitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? -80.124528
    }

    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 26.465019, longitude: -80.124528),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var trackingMode: MapUserTrackingMode = .follow

    private var profileName: String {
        let fullName = [storedFirstName, storedLastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return fullName.isEmpty ? "Peter Balsamo" : fullName
    }

    private let profileCity = "Delray Beach"
    private let profileState = "Florida"

    private var profileTitle: String {
        let phone = storedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        return phone.isEmpty ? "Employee" : phone
    }

    private let profileDescription = "I am a happy user of TheLight."

    private func loadSecureSettings() {
        storedLatitude = SecureSettingsStore.loadString(forKey: SettingsUI.latitudeKey)
        storedLongitude = SecureSettingsStore.loadString(forKey: SettingsUI.longitudeKey)
        storedFirstName = SecureSettingsStore.loadString(forKey: SettingsUI.firstNameKey)
        storedLastName = SecureSettingsStore.loadString(forKey: SettingsUI.lastNameKey)
        storedPhone = SecureSettingsStore.loadString(forKey: SettingsUI.phoneKey)
    }

    private func updateRegionFromSettings() {
        let center = CLLocationCoordinate2D(latitude: latitudeValue, longitude: longitudeValue)
        coordinateRegion.center = center
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            profileMap
            profileImage
            profileDetails
        }
        .onAppear {
            loadSecureSettings()
            updateRegionFromSettings()
        }
        .task { await viewModel.fetchCurrentUser() }
        .onChange(of: storedLatitude) { _ in updateRegionFromSettings() }
        .onChange(of: storedLongitude) { _ in updateRegionFromSettings() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileMap: some View {
        ProfileLocationMap(
            coordinateRegion: $coordinateRegion,
            trackingMode: $trackingMode
        )
        .ignoresSafeArea(edges: .top)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: 4)
    }

    private var profileImage: some View {
        ProfileAvatarImage(urlString: viewModel.chatUser?.profileImageUrl)
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .offset(y: -130)
            .padding(.bottom, -130)
    }

    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profileName)
                .font(.title)
                .foregroundColor(.primary)

            HStack {
                Text(profileCity)
                Spacer()
                Text(profileState)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Divider()

            Text(profileTitle)
                .font(.title2)
            Text(profileDescription)
        }
        .padding()
    }
}

private struct ProfileLocationMap: View {
    @Binding var coordinateRegion: MKCoordinateRegion
    @Binding var trackingMode: MapUserTrackingMode

    var body: some View {
        if #available(iOS 17.0, *) {
            ModernProfileLocationMap(coordinateRegion: coordinateRegion)
        } else {
            Map(
                coordinateRegion: $coordinateRegion,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $trackingMode
            )
        }
    }
}

@available(iOS 17.0, *)
private struct ModernProfileLocationMap: View {
    @State private var position: MapCameraPosition

    init(coordinateRegion: MKCoordinateRegion) {
        _position = State(initialValue: .region(coordinateRegion))
    }

    var body: some View {
        Map(position: $position, interactionModes: .all) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview("User Profile - Dark") {
    NavigationStack {
        UserFormUI()
    }
    .preferredColorScheme(.dark)
}
