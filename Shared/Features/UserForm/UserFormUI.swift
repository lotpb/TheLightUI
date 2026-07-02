//
//  UserFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 4/30/21.
//

import SwiftUI
import MapKit

struct UserFormUI: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel = MainMessagesViewModel()
    @State private var profile = UserFormProfile()

    // Fallbacks shown until reverse geocoding of the stored coordinate completes.
    @State private var profileCity = "Delray Beach"
    @State private var profileState = "Florida"

    private let profileRole = "User"
    private let profileDescription = "Another happy user of TheLight."

    var body: some View {
        ScrollView {
            profileMap
            profileImage
            profileDetails
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { profile = UserFormProfile.loadFromSecureSettings() }
        .task { await viewModel.fetchCurrentUser() }
        // Re-geocode whenever the stored coordinates load or change.
        .task(id: "\(profile.latitude),\(profile.longitude)") { await updateCityAndState() }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Fills the city/state card from the same coordinate the profile map shows,
    // keeping the fallbacks when geocoding fails (e.g. offline).
    private func updateCityAndState() async {
        let place = await ProfilePlaceLookup.cityAndState(for: profile.coordinate)
        if let city = place.city {
            profileCity = city
        }
        if let state = place.state {
            profileState = state
        }
    }

    private var profileMap: some View {
        ProfileLocationMap(coordinate: profile.coordinate, markerTitle: profile.displayName)
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
                Text(profile.displayName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(profileRole)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                if !profile.trimmedPhone.isEmpty {
                    phoneCard
                }

                if !profile.trimmedEmail.isEmpty {
                    emailCard
                }

                ProfileCardRow(label: "location", value: "\(profileCity), \(profileState)")
                ProfileCardRow(label: "notes", value: profileDescription)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    // Phone card with a trailing call button, in the style of Contacts.
    private var phoneCard: some View {
        ProfileCardRow(
            label: "phone",
            value: profile.trimmedPhone,
            action: ProfileCardRow.Action(systemImage: "phone.fill", accessibilityLabel: "Call \(profile.displayName)") {
                openURL.callPhoneNumber(profile.trimmedPhone)
            }
        )
    }

    // Email card with a trailing compose button, in the style of Contacts.
    private var emailCard: some View {
        ProfileCardRow(
            label: "email",
            value: profile.trimmedEmail,
            truncatesValue: true,
            action: ProfileCardRow.Action(systemImage: "envelope.fill", accessibilityLabel: "Email \(profile.displayName)") {
                if let url = URL(string: "mailto:\(profile.trimmedEmail)") {
                    openURL(url)
                }
            }
        )
    }
}

// A Contacts-style field card: small secondary label above the value,
// with an optional trailing action button such as call or compose.
private struct ProfileCardRow: View {
    struct Action {
        let systemImage: String
        let accessibilityLabel: String
        let handler: () -> Void
    }

    let label: String
    let value: String
    var truncatesValue = false
    var action: Action?

    private var valueLineLimit: Int? {
        truncatesValue ? 1 : nil
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(value)
                    .foregroundStyle(Color.primary)
                    .lineLimit(valueLineLimit)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)

            if let action {
                // Wrapped in a closure: previews reject function values passed directly.
                Button(action: { action.handler() }) {
                    Image(systemName: action.systemImage)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color(.tertiarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.accessibilityLabel)
            }
        }
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
