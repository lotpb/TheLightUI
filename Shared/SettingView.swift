//
//  SettingView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI

// MARK: - Settings Keys
enum SettingsUI {
    static let firstNameKey = "firstName"
    static let lastNameKey = "lastName"
    static let emailKey = "email"
    static let phoneKey = "phone"
    static let passwordKey = "password"
    static let usernameKey = "username"
    static let websiteKey = "website"

    static let isCompanyNameKey = "isCompanyName"
    static let isSubscribedKey = "isSubscriber"
    static let backend = "backend"
    static let isBackfetch = "isbackfetch"
    static let isAutolockKey = "isautolock"

    static let color = "color"

    static let isSpeakKey = "isSpeak"
    static let isMusicKey = "isMusic"

    static let latitudeKey = "latitude"
    static let longtitudeKey = "longtitude"

    static let eventKey = "event"
    static let durationKey = "duration"

    static let areacodeKey = "areacode"
    static let emailTitleKey = "emailtitle"
    static let emailMessageKey = "emailmessage"
    static let versionKey = "version"
}

// MARK: - Settings Form
struct SettingView: View {
    private enum BackendOption: String, CaseIterable, Identifiable {
        case firebase = "Firebase"
        case parse = "Parse"

        var id: Self { self }
    }

    private enum ThemeOption: Int, CaseIterable, Identifiable {
        case purple = 0
        case orange = 1

        var id: Self { self }

        var title: String {
            switch self {
            case .purple: return "Purple"
            case .orange: return "Orange"
            }
        }
    }

    @AppStorage(SettingsUI.firstNameKey) private var firstName = ""
    @AppStorage(SettingsUI.lastNameKey) private var lastname = ""
    @AppStorage(SettingsUI.emailKey) private var email = ""
    @AppStorage(SettingsUI.phoneKey) private var phone = ""
    @AppStorage(SettingsUI.passwordKey) private var password = ""
    @AppStorage(SettingsUI.usernameKey) private var username = ""
    @AppStorage(SettingsUI.websiteKey) private var website = ""

    @AppStorage(SettingsUI.isCompanyNameKey) private var companyName = "TheLight Software"
    @AppStorage(SettingsUI.isSubscribedKey) private var isSubscriber = false
    @AppStorage(SettingsUI.backend) private var backend = "Firebase"
    @AppStorage(SettingsUI.isBackfetch) private var isBackfetch = false
    @AppStorage(SettingsUI.isAutolockKey) private var isAutoLockDisabled = false

    @AppStorage(SettingsUI.color) private var color = 0
    @AppStorage(SettingsUI.isSpeakKey) private var isSpeak = false
    @AppStorage(SettingsUI.isMusicKey) private var isMusic = false

    @AppStorage(SettingsUI.latitudeKey) private var latitude = ""
    @AppStorage(SettingsUI.longtitudeKey) private var longitude = ""
    @AppStorage(SettingsUI.eventKey) private var event = ""
    @AppStorage(SettingsUI.durationKey) private var duration = ""
    @AppStorage(SettingsUI.areacodeKey) private var areaCode = ""
    @AppStorage(SettingsUI.emailTitleKey) private var emailTitle = ""
    @AppStorage(SettingsUI.emailMessageKey) private var emailMessage = ""
    @AppStorage(SettingsUI.versionKey) private var version = "1.0"

    var body: some View {
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private var settingsForm: some View {
        Form {
            accountSection
            memberSection
            themeSection
            soundsSection
            mapSection
            calendarSection
            generalSection
        }
    }

    private var accountSection: some View {
        Section("TheLight Settings") {
            settingsTextField("First Name", text: $firstName)
            settingsTextField("Last Name", text: $lastname)
            settingsTextField("Email", text: $email, keyboardType: .emailAddress, textInputAutocapitalization: .never)
            settingsTextField("Phone", text: $phone, keyboardType: .phonePad)
            passwordField
            settingsTextField("Username", text: $username, textInputAutocapitalization: .never)
            settingsTextField("Website", text: $website, keyboardType: .URL, textInputAutocapitalization: .never)
        }
    }

    private var memberSection: some View {
        Section("Member Status") {
            settingsTextField("Company", text: $companyName)
            SettingsToggleRow(title: "Subscriber", isOn: $isSubscriber)
            backendPicker
            SettingsToggleRow(title: "Background Fetch", isOn: $isBackfetch)
            SettingsToggleRow(title: "Prevent Auto-Lock", isOn: $isAutoLockDisabled)
            termsDisclosure
        }
    }

    private var themeSection: some View {
        Section("Theme") {
            Picker("Color Scheme", selection: $color) {
                ForEach(ThemeOption.allCases) { option in
                    Text(option.title)
                        .tag(option.rawValue)
                }
            }
        }
    }

    private var soundsSection: some View {
        Section("Sounds") {
            SettingsToggleRow(title: "Speak", isOn: $isSpeak)
            SettingsToggleRow(title: "Music", isOn: $isMusic)
        }
    }

    private var mapSection: some View {
        Section("Map") {
            settingsTextField("Latitude", text: $latitude, keyboardType: .decimalPad)
            settingsTextField("Longitude", text: $longitude, keyboardType: .decimalPad)
        }
    }

    private var calendarSection: some View {
        Section("Calendar") {
            settingsTextField("Event", text: $event)
            settingsTextField("Duration", text: $duration)
        }
    }

    private var generalSection: some View {
        Section("General") {
            settingsTextField("Area Code", text: $areaCode, keyboardType: .numberPad)
            settingsTextField("Email Title", text: $emailTitle)
            settingsTextField("Email Message", text: $emailMessage)
            settingsTextField("Version", text: $version)
        }
    }

    // MARK: - Rows

    private var backendPicker: some View {
        Picker("Backend Data", selection: $backend) {
            ForEach(BackendOption.allCases) { option in
                Text(option.rawValue)
                    .tag(option.rawValue)
            }
        }
    }

    private var termsDisclosure: some View {
        DisclosureGroup("Show Terms") {
            Text("Long terms and conditions here long terms and conditions here long terms and conditions here long terms and conditions here.")
                .foregroundColor(.secondary)
        }
    }

    private var passwordField: some View {
        HStack {
            Text("Password")
            Spacer()
            SecureField("Password", text: $password)
                .settingsFieldStyle()
        }
    }

    private func settingsTextField(
        _ title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textInputAutocapitalization: TextInputAutocapitalization? = nil
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: text)
                .settingsFieldStyle()
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
        }
    }
}

// MARK: - Styles
private extension View {
    func settingsFieldStyle() -> some View {
        multilineTextAlignment(.trailing)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
    }
}

// MARK: - Preview
#Preview("Settings - Dark") {
    SettingView()
        .preferredColorScheme(.dark)
}
