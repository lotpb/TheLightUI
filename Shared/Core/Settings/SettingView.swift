//
//  SettingView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI

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

    @StateObject private var settings: AppSettingsStore

    init(settings: AppSettingsStore = AppSettingsStore()) {
        _settings = StateObject(wrappedValue: settings)
    }

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
            settingsTextField("First Name", text: $settings.firstName)
            settingsTextField("Last Name", text: $settings.lastName)
            settingsTextField("Email", text: $settings.email, keyboardType: .emailAddress, textInputAutocapitalization: .never)
            settingsTextField("Phone", text: $settings.phone, keyboardType: .phonePad)
            settingsTextField("Username", text: $settings.username, textInputAutocapitalization: .never)
            //settingsTextField("Website", text: $settings.website, keyboardType: .URL, textInputAutocapitalization: .never)
        }
    }

    private var memberSection: some View {
        Section("Member Status") {
            settingsTextField("Company", text: $settings.companyName)
            SettingsToggleRow(title: "Subscriber", isOn: $settings.isSubscriber)
            backendPicker
            SettingsToggleRow(title: "Background Fetch", isOn: $settings.isBackfetch)
            SettingsToggleRow(title: "Prevent Auto-Lock", isOn: $settings.isAutoLockDisabled)
            termsDisclosure
        }
    }

    private var themeSection: some View {
        Section("Theme") {
            Picker("Color Scheme", selection: $settings.color) {
                ForEach(ThemeOption.allCases) { option in
                    Text(option.title)
                        .tag(option.rawValue)
                }
            }
        }
    }

    private var soundsSection: some View {
        Section("Sounds") {
            SettingsToggleRow(title: "Speak", isOn: $settings.isSpeak)
            SettingsToggleRow(title: "Music", isOn: $settings.isMusic)
        }
    }

    private var mapSection: some View {
        Section("Map") {
            settingsTextField("Latitude", text: $settings.latitude, keyboardType: .decimalPad)
            settingsTextField("Longitude", text: $settings.longitude, keyboardType: .numbersAndPunctuation)
        }
    }

    private var calendarSection: some View {
        Section("Calendar") {
            settingsTextField("Event", text: $settings.event)
            settingsTextField("Duration", text: $settings.duration)
        }
    }

    private var generalSection: some View {
        Section("General") {
            settingsTextField("Area Code", text: $settings.areaCode, keyboardType: .numberPad)
            settingsTextField("Email Title", text: $settings.emailTitle)
            settingsTextField("Email Message", text: $settings.emailMessage)
            settingsTextField("Version", text: $settings.version)
        }
    }

    // MARK: - Rows

    private var backendPicker: some View {
        Picker("Backend Data", selection: $settings.backend) {
            ForEach(BackendOption.allCases) { option in
                Text(option.rawValue)
                    .tag(option.rawValue)
            }
        }
    }

    private var termsDisclosure: some View {
        DisclosureGroup("Show Terms") {
            Text("By using our Services (website, app, or software), you agree to these Terms. If you don’t agree, stop using them.")
                .foregroundColor(.secondary)
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

