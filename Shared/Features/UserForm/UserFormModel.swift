//
//  UserFormModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 7/2/26.
//

import CoreLocation

/// Profile fields shown by `UserFormUI`, loaded from the shared secure settings store.
struct UserFormProfile {
    // Fallback location used until the user's stored coordinates load.
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 26.465019, longitude: -80.124528)

    var firstName = ""
    var lastName = ""
    var phone = ""
    var email = ""
    var latitude = ""
    var longitude = ""

    static func loadFromSecureSettings() -> UserFormProfile {
        UserFormProfile(
            firstName: SecureSettingsStore.loadString(forKey: SettingsUI.firstNameKey),
            lastName: SecureSettingsStore.loadString(forKey: SettingsUI.lastNameKey),
            phone: SecureSettingsStore.loadString(forKey: SettingsUI.phoneKey),
            email: SecureSettingsStore.loadString(forKey: SettingsUI.emailKey),
            latitude: SecureSettingsStore.loadString(forKey: SettingsUI.latitudeKey),
            longitude: SecureSettingsStore.loadString(forKey: SettingsUI.longitudeKey)
        )
    }

    /// Parses the stored latitude/longitude, falling back per axis when missing or malformed.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.latitude,
            longitude: Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultCoordinate.longitude
        )
    }

    var displayName: String {
        let fullName = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return fullName.isEmpty ? "Peter Balsamo" : fullName
    }

    var trimmedPhone: String {
        phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Reverse-geocodes a coordinate into display-ready city/state for the profile's location card.
enum ProfilePlaceLookup {
    // CLPlacemark.administrativeArea returns US state abbreviations; show full names.
    private static let usStateNames: [String: String] = [
        "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas",
        "CA": "California", "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware",
        "FL": "Florida", "GA": "Georgia", "HI": "Hawaii", "ID": "Idaho",
        "IL": "Illinois", "IN": "Indiana", "IA": "Iowa", "KS": "Kansas",
        "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine", "MD": "Maryland",
        "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota", "MS": "Mississippi",
        "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada",
        "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico", "NY": "New York",
        "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma",
        "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island", "SC": "South Carolina",
        "SD": "South Dakota", "TN": "Tennessee", "TX": "Texas", "UT": "Utah",
        "VT": "Vermont", "VA": "Virginia", "WA": "Washington", "WV": "West Virginia",
        "WI": "Wisconsin", "WY": "Wyoming", "DC": "District of Columbia", "PR": "Puerto Rico"
    ]

    /// Returns the locality and full state name, or nils when geocoding fails (e.g. offline).
    static func cityAndState(for coordinate: CLLocationCoordinate2D) async -> (city: String?, state: String?) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return (nil, nil)
        }
        let state = placemark.administrativeArea.map { usStateNames[$0] ?? $0 }
        return (placemark.locality, state)
    }
}
