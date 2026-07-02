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

    @Environment(\.openURL) private var openURL
    @State private var viewModel = MainMessagesViewModel()

    @State private var storedLatitude = ""
    @State private var storedLongitude = ""
    @State private var storedFirstName = ""
    @State private var storedLastName = ""
    @State private var storedPhone = ""
    @State private var storedEmail = ""

    // Parse stored latitude/longitude with sensible defaults.
    private var latitudeValue: Double {
        Double(storedLatitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.latitude
    }
    private var longitudeValue: Double {
        Double(storedLongitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.longitude
    }

    private var storedCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitudeValue, longitude: longitudeValue)
    }

    private var profileName: String {
        let fullName = [storedFirstName, storedLastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return fullName.isEmpty ? "Peter Balsamo" : fullName
    }

    private let profileCity = "Delray Beach"
    private let profileState = "Florida"
    private let profileRole = "Employee"
    private let profileDescription = "I am a happy user of TheLight."

    private var trimmedPhone: String {
        storedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        storedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadSecureSettings() {
        storedLatitude = SecureSettingsStore.loadString(forKey: SettingsUI.latitudeKey)
        storedLongitude = SecureSettingsStore.loadString(forKey: SettingsUI.longitudeKey)
        storedFirstName = SecureSettingsStore.loadString(forKey: SettingsUI.firstNameKey)
        storedLastName = SecureSettingsStore.loadString(forKey: SettingsUI.lastNameKey)
        storedPhone = SecureSettingsStore.loadString(forKey: SettingsUI.phoneKey)
        storedEmail = SecureSettingsStore.loadString(forKey: SettingsUI.emailKey)
    }

    var body: some View {
        ScrollView {
            profileMap
            profileImage
            profileDetails
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadSecureSettings)
        .task { await viewModel.fetchCurrentUser() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileMap: some View {
        ProfileLocationMap(coordinate: storedCoordinate, markerTitle: profileName)
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
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(profileName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(profileRole)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                if !trimmedPhone.isEmpty {
                    phoneCard
                }

                if !trimmedEmail.isEmpty {
                    emailCard
                }

                contactCard(label: "location", value: "\(profileCity), \(profileState)")
                contactCard(label: "notes", value: profileDescription)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    // Phone card with a trailing call button, in the style of Contacts.
    private var phoneCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("phone")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(trimmedPhone)
                    .foregroundStyle(Color.primary)
            }

            Spacer()

            Button {
                openURL.callPhoneNumber(trimmedPhone)
            } label: {
                Image(systemName: "phone.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(Color(.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Call \(profileName)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // Email card with a trailing compose button, in the style of Contacts.
    private var emailCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("email")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(trimmedEmail)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                if let url = URL(string: "mailto:\(trimmedEmail)") {
                    openURL(url)
                }
            } label: {
                Image(systemName: "envelope.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(Color(.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Email \(profileName)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // A Contacts-style field card: small secondary label above the value.
    private func contactCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ProfileLocationMap: View {
    let coordinate: CLLocationCoordinate2D
    let markerTitle: String
    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D, markerTitle: String) {
        self.coordinate = coordinate
        self.markerTitle = markerTitle
        _position = State(initialValue: Self.camera(for: coordinate))
    }

    var body: some View {
        Map(position: $position, interactionModes: .all) {
            Marker(markerTitle, systemImage: "person.fill", coordinate: coordinate)
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        // Recenter when the stored coordinates load or change.
        // CLLocationCoordinate2D isn't Equatable, so observe its components.
        .onChange(of: coordinate.latitude) {
            position = Self.camera(for: coordinate)
        }
        .onChange(of: coordinate.longitude) {
            position = Self.camera(for: coordinate)
        }
    }

    private static func camera(for coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))
    }
}

#Preview("User Profile - Dark") {
    NavigationStack {
        UserFormUI()
    }
    .preferredColorScheme(.dark)
}
