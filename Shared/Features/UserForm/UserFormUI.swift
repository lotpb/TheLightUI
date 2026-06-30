//
//  UserFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 4/30/21.
//

import SwiftUI
import MapKit

struct UserFormUI: View {
    // Fallback location used until the user's stored coordinates load.
    private static let defaultCoordinate = CLLocationCoordinate2D(latitude: 26.465019, longitude: -80.124528)

    @State private var viewModel = MainMessagesViewModel()

    @State private var storedLatitude = ""
    @State private var storedLongitude = ""
    @State private var storedFirstName = ""
    @State private var storedLastName = ""
    @State private var storedPhone = ""

    // Parse stored latitude/longitude with sensible defaults.
    private var latitudeValue: Double {
        Double(storedLatitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.latitude
    }
    private var longitudeValue: Double {
        Double(storedLongitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.longitude
    }

    @State private var coordinateRegion = MKCoordinateRegion(
        center: UserFormUI.defaultCoordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    

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
        ScrollView {
            profileMap
            profileImage
            profileDetails
        }
        .onAppear {
            loadSecureSettings()
            updateRegionFromSettings()
        }
        .task { await viewModel.fetchCurrentUser() }
        .onChange(of: storedLatitude) { updateRegionFromSettings() }
        .onChange(of: storedLongitude) { updateRegionFromSettings() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileMap: some View {
        ProfileLocationMap(
            coordinateRegion: $coordinateRegion
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
                .foregroundStyle(Color.primary)

            HStack {
                Text(profileCity)
                Spacer()
                Text(profileState)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

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
    @State private var position: MapCameraPosition

    init(coordinateRegion: Binding<MKCoordinateRegion>) {
        _coordinateRegion = coordinateRegion
        _position = State(initialValue: .region(coordinateRegion.wrappedValue))
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
        // Follow the region when stored coordinates load or change.
        // MKCoordinateRegion isn't Equatable, so observe its center components.
        .onChange(of: coordinateRegion.center.latitude) {
            position = .region(coordinateRegion)
        }
        .onChange(of: coordinateRegion.center.longitude) {
            position = .region(coordinateRegion)
        }
    }
}

#Preview("User Profile - Dark") {
    NavigationStack {
        UserFormUI()
    }
    .preferredColorScheme(.dark)
}
