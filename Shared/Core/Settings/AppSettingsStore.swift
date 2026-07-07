//
//  AppSettingsStore.swift
//  TheLightUI
//

import Foundation
import Observation

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

    //static let isSpeakKey = "isSpeak"
    //static let isMusicKey = "isMusic"

    static let latitudeKey = "latitude"
    static let longitudeKey = "longitude"
    //static let legacyLongtitudeKey = "longtitude"

    static let eventKey = "event"
    static let durationKey = "120"

    static let areacodeKey = "516"
    static let emailTitleKey = "TheLight Support"
    static let emailMessageKey = "Thank you for using TheLight"
    static let versionKey = "1.0"
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

@Observable
final class AppSettingsStore {
    var firstName: String = "" { didSet { saveSecureString(firstName, forKey: SettingsUI.firstNameKey) } }
    var lastName: String = "" { didSet { saveSecureString(lastName, forKey: SettingsUI.lastNameKey) } }
    var email: String = "" { didSet { saveSecureString(email, forKey: SettingsUI.emailKey) } }
    var phone: String = "" { didSet { saveSecureString(phone, forKey: SettingsUI.phoneKey) } }
    var username: String = "" { didSet { defaults.set(username, forKey: SettingsUI.usernameKey) } }
    //var website: String = "" { didSet { defaults.set(website, forKey: SettingsUI.websiteKey) } }

    var companyName: String = "TheLight Software" { didSet { defaults.set(companyName, forKey: SettingsUI.isCompanyNameKey) } }
    var isSubscriber: Bool = false { didSet { defaults.set(isSubscriber, forKey: SettingsUI.isSubscribedKey) } }
    var backend: String = "Firebase" { didSet { defaults.set(backend, forKey: SettingsUI.backend) } }
    var isBackfetch: Bool = false { didSet { defaults.set(isBackfetch, forKey: SettingsUI.isBackfetch) } }
    var color: Int = 0 { didSet { defaults.set(color, forKey: SettingsUI.color) } }
    
    //var isAutoLockDisabled: Bool = false { didSet { defaults.set(isAutoLockDisabled, forKey: SettingsUI.isAutolockKey) } }
    //var isSpeak: Bool = false { didSet { defaults.set(isSpeak, forKey: SettingsUI.isSpeakKey) } }
    //var isMusic: Bool = false { didSet { defaults.set(isMusic, forKey: SettingsUI.isMusicKey) } }

    var latitude: String = "" { didSet { saveSecureString(latitude, forKey: SettingsUI.latitudeKey) } }
    var longitude: String = "" { didSet { saveSecureString(longitude, forKey: SettingsUI.longitudeKey) } }
    var event: String = "" { didSet { defaults.set(event, forKey: SettingsUI.eventKey) } }
    var duration: String = "" { didSet { defaults.set(duration, forKey: SettingsUI.durationKey) } }
    var areaCode: String = "" { didSet { defaults.set(areaCode, forKey: SettingsUI.areacodeKey) } }
    var emailTitle: String = "" { didSet { defaults.set(emailTitle, forKey: SettingsUI.emailTitleKey) } }
    var emailMessage: String = "" { didSet { defaults.set(emailMessage, forKey: SettingsUI.emailMessageKey) } }
    var version: String = "1.0" { didSet { defaults.set(version, forKey: SettingsUI.versionKey) } }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let passwordStore: PasswordStoring

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
        username = defaults.string(forKey: SettingsUI.usernameKey) ?? username
        //website = defaults.string(forKey: SettingsUI.websiteKey) ?? website

        companyName = defaults.string(forKey: SettingsUI.isCompanyNameKey) ?? companyName
        isSubscriber = defaults.bool(forKey: SettingsUI.isSubscribedKey)
        backend = defaults.string(forKey: SettingsUI.backend) ?? backend
        isBackfetch = defaults.bool(forKey: SettingsUI.isBackfetch)
        color = defaults.object(forKey: SettingsUI.color) as? Int ?? color
        
        //isAutoLockDisabled = defaults.bool(forKey: SettingsUI.isAutolockKey)
        //isSpeak = defaults.bool(forKey: SettingsUI.isSpeakKey)
        //isMusic = defaults.bool(forKey: SettingsUI.isMusicKey)

        // Migrate legacy misspelled key "longtitude" to the corrected "longitude" key if present
//        let legacyLongitude = SecureSettingsStore.loadString(forKey: SettingsUI.legacyLongtitudeKey, defaults: defaults, passwordStore: passwordStore)
//        if !legacyLongitude.isEmpty {
//            SecureSettingsStore.removeString(forKey: SettingsUI.legacyLongtitudeKey, defaults: defaults, passwordStore: passwordStore)
//            saveSecureString(legacyLongitude, forKey: SettingsUI.longitudeKey)
//        }
        
        latitude = Self.loadSecureString(forKey: SettingsUI.latitudeKey, defaults: defaults, passwordStore: passwordStore)
        longitude = Self.loadSecureString(forKey: SettingsUI.longitudeKey, defaultValue: "-80.124528", defaults: defaults, passwordStore: passwordStore)

        event = defaults.string(forKey: SettingsUI.eventKey) ?? event
        duration = defaults.string(forKey: SettingsUI.durationKey) ?? duration
        areaCode = defaults.string(forKey: SettingsUI.areacodeKey) ?? areaCode
        emailTitle = defaults.string(forKey: SettingsUI.emailTitleKey) ?? emailTitle
        emailMessage = defaults.string(forKey: SettingsUI.emailMessageKey) ?? emailMessage
        version = defaults.string(forKey: SettingsUI.versionKey) ?? version

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

