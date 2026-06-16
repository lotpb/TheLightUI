//
//  AppSettingsStore.swift
//  TheLightUI
//

import Foundation

// MARK: - Settings Keys
enum SettingsUI {
    static let firstNameKey = "firstName"
    static let lastNameKey = "lastName"
    static let emailKey = "email"
    static let phoneKey = "phone"
    static let legacyPasswordKey = "password"
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

enum SecureSettingsStore {
    static func loadString(
        forKey key: String,
        defaultValue: String = "",
        defaults: UserDefaults = .standard,
        passwordStore: PasswordStoring = KeychainPasswordStore()
    ) -> String {
        if let defaultsValue = defaults.string(forKey: key) {
            saveString(defaultsValue, forKey: key, defaults: defaults, passwordStore: passwordStore)
            return defaultsValue
        }

        let keychainValue = passwordStore.loadPassword(for: key)
        return keychainValue.isEmpty ? defaultValue : keychainValue
    }

    static func saveString(
        _ value: String,
        forKey key: String,
        defaults: UserDefaults = .standard,
        passwordStore: PasswordStoring = KeychainPasswordStore()
    ) {
        defaults.removeObject(forKey: key)
        passwordStore.savePassword(value, for: key)
    }

    static func removeString(
        forKey key: String,
        defaults: UserDefaults = .standard,
        passwordStore: PasswordStoring = KeychainPasswordStore()
    ) {
        defaults.removeObject(forKey: key)
        passwordStore.deletePassword(for: key)
    }
}

final class AppSettingsStore: ObservableObject {
    @Published var firstName: String { didSet { saveSecureString(firstName, forKey: SettingsUI.firstNameKey) } }
    @Published var lastName: String { didSet { saveSecureString(lastName, forKey: SettingsUI.lastNameKey) } }
    @Published var email: String { didSet { saveSecureString(email, forKey: SettingsUI.emailKey) } }
    @Published var phone: String { didSet { saveSecureString(phone, forKey: SettingsUI.phoneKey) } }
    @Published var username: String { didSet { defaults.set(username, forKey: SettingsUI.usernameKey) } }
    @Published var website: String { didSet { defaults.set(website, forKey: SettingsUI.websiteKey) } }

    @Published var companyName: String { didSet { defaults.set(companyName, forKey: SettingsUI.isCompanyNameKey) } }
    @Published var isSubscriber: Bool { didSet { defaults.set(isSubscriber, forKey: SettingsUI.isSubscribedKey) } }
    @Published var backend: String { didSet { defaults.set(backend, forKey: SettingsUI.backend) } }
    @Published var isBackfetch: Bool { didSet { defaults.set(isBackfetch, forKey: SettingsUI.isBackfetch) } }
    @Published var isAutoLockDisabled: Bool { didSet { defaults.set(isAutoLockDisabled, forKey: SettingsUI.isAutolockKey) } }

    @Published var color: Int { didSet { defaults.set(color, forKey: SettingsUI.color) } }

    @Published var isSpeak: Bool { didSet { defaults.set(isSpeak, forKey: SettingsUI.isSpeakKey) } }
    @Published var isMusic: Bool { didSet { defaults.set(isMusic, forKey: SettingsUI.isMusicKey) } }

    @Published var latitude: String { didSet { saveSecureString(latitude, forKey: SettingsUI.latitudeKey) } }
    @Published var longitude: String { didSet { saveSecureString(longitude, forKey: SettingsUI.longtitudeKey) } }
    @Published var event: String { didSet { defaults.set(event, forKey: SettingsUI.eventKey) } }
    @Published var duration: String { didSet { defaults.set(duration, forKey: SettingsUI.durationKey) } }
    @Published var areaCode: String { didSet { defaults.set(areaCode, forKey: SettingsUI.areacodeKey) } }
    @Published var emailTitle: String { didSet { defaults.set(emailTitle, forKey: SettingsUI.emailTitleKey) } }
    @Published var emailMessage: String { didSet { defaults.set(emailMessage, forKey: SettingsUI.emailMessageKey) } }
    @Published var version: String { didSet { defaults.set(version, forKey: SettingsUI.versionKey) } }

    private let defaults: UserDefaults
    private let passwordStore: PasswordStoring

    init(
        defaults: UserDefaults = .standard,
        passwordStore: PasswordStoring = KeychainPasswordStore()
    ) {
        self.defaults = defaults
        self.passwordStore = passwordStore

        firstName = Self.loadSecureString(forKey: SettingsUI.firstNameKey, defaults: defaults, passwordStore: passwordStore)
        lastName = Self.loadSecureString(forKey: SettingsUI.lastNameKey, defaults: defaults, passwordStore: passwordStore)
        email = Self.loadSecureString(forKey: SettingsUI.emailKey, defaults: defaults, passwordStore: passwordStore)
        phone = Self.loadSecureString(forKey: SettingsUI.phoneKey, defaults: defaults, passwordStore: passwordStore)
        username = defaults.string(forKey: SettingsUI.usernameKey) ?? ""
        website = defaults.string(forKey: SettingsUI.websiteKey) ?? ""

        companyName = defaults.string(forKey: SettingsUI.isCompanyNameKey) ?? "TheLight Software"
        isSubscriber = defaults.bool(forKey: SettingsUI.isSubscribedKey)
        backend = defaults.string(forKey: SettingsUI.backend) ?? "Firebase"
        isBackfetch = defaults.bool(forKey: SettingsUI.isBackfetch)
        isAutoLockDisabled = defaults.bool(forKey: SettingsUI.isAutolockKey)

        color = defaults.object(forKey: SettingsUI.color) as? Int ?? 0

        isSpeak = defaults.bool(forKey: SettingsUI.isSpeakKey)
        isMusic = defaults.bool(forKey: SettingsUI.isMusicKey)

        latitude = Self.loadSecureString(forKey: SettingsUI.latitudeKey, defaults: defaults, passwordStore: passwordStore)
        longitude = Self.loadSecureString(
            forKey: SettingsUI.longtitudeKey,
            defaultValue: "-80.124528",
            defaults: defaults,
            passwordStore: passwordStore
        )
        event = defaults.string(forKey: SettingsUI.eventKey) ?? ""
        duration = defaults.string(forKey: SettingsUI.durationKey) ?? ""
        areaCode = defaults.string(forKey: SettingsUI.areacodeKey) ?? ""
        emailTitle = defaults.string(forKey: SettingsUI.emailTitleKey) ?? ""
        emailMessage = defaults.string(forKey: SettingsUI.emailMessageKey) ?? ""
        version = defaults.string(forKey: SettingsUI.versionKey) ?? "1.0"

        SecureSettingsStore.removeString(
            forKey: SettingsUI.legacyPasswordKey,
            defaults: defaults,
            passwordStore: passwordStore
        )
    }

    private static func loadSecureString(
        forKey key: String,
        defaultValue: String = "",
        defaults: UserDefaults,
        passwordStore: PasswordStoring
    ) -> String {
        SecureSettingsStore.loadString(
            forKey: key,
            defaultValue: defaultValue,
            defaults: defaults,
            passwordStore: passwordStore
        )
    }

    private func saveSecureString(_ value: String, forKey key: String) {
        SecureSettingsStore.saveString(
            value,
            forKey: key,
            defaults: defaults,
            passwordStore: passwordStore
        )
    }
}

