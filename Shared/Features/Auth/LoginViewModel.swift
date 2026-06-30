//
//  LoginViewModel.swift
//  TheLightUI
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class LoginViewModel {
    var isLoginMode = true
    var firstName = ""
    var lastName = ""
    var phoneNumber = ""
    var email = ""
    var password = ""
    var image: UIImage?
    private(set) var isAuthenticated = false
    private(set) var isProcessing = false
    var loginStatusMessage = ""

    @ObservationIgnored private let loginService: LoginServicing
    @ObservationIgnored private let authenticationService: AuthenticationService
    @ObservationIgnored private let didCompleteLoginProcess: () -> Void
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let passwordStore: PasswordStoring
    @ObservationIgnored private var authTask: Task<Void, Never>?

    var navigationTitle: String {
        isLoginMode ? "Log In" : "Create Account"
    }

    var primaryActionTitle: String {
        isLoginMode ? "Log In" : "Create Account"
    }

    init(
        loginService: LoginServicing = FirebaseLoginService(),
        authenticationService: AuthenticationService = AuthenticationService(),
        defaults: UserDefaults = .standard,
        passwordStore: PasswordStoring = KeychainPasswordStore(),
        didCompleteLoginProcess: @escaping () -> Void
    ) {
        self.loginService = loginService
        self.authenticationService = authenticationService
        self.defaults = defaults
        self.passwordStore = passwordStore
        self.didCompleteLoginProcess = didCompleteLoginProcess
    }

    deinit {
        authTask?.cancel()
    }

    func handlePrimaryAction() {
        guard !isProcessing else { return }

        authTask?.cancel()
        authTask = Task { [weak self] in
            guard let self else { return }
            isProcessing = true
            defer { isProcessing = false }

            if isLoginMode {
                await loginUser()
            } else {
                await createNewAccount()
            }
        }
    }

    func sendPasswordReset() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loginStatusMessage = "Enter your email address before resetting your password."
            return
        }
        guard !isProcessing else { return }

        authTask?.cancel()
        authTask = Task { [weak self] in
            guard let self else { return }
            isProcessing = true
            defer { isProcessing = false }

            do {
                try await loginService.sendPasswordReset(email: trimmedEmail)
                guard !Task.isCancelled else { return }
                loginStatusMessage = "Password reset email sent to \(trimmedEmail)."
            } catch is CancellationError {
                return
            } catch {
                loginStatusMessage = "Failed to send password reset: \(error.localizedDescription)"
            }
        }
    }

    func formatPhoneNumber(_ value: String) {
        let digits = value.filter { $0.isNumber }.prefix(10)
        let formattedPhoneNumber: String

        switch digits.count {
        case 0:
            formattedPhoneNumber = ""
        case 1...3:
            formattedPhoneNumber = "(" + digits
        case 4...6:
            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3)
            formattedPhoneNumber = "(\(areaCode)) \(prefix)"
        default:
            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let lineNumber = digits.dropFirst(6)
            formattedPhoneNumber = "(\(areaCode)) \(prefix)-\(lineNumber)"
        }

        guard phoneNumber != formattedPhoneNumber else { return }
        phoneNumber = formattedPhoneNumber
    }

    private func updateSettings(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String
    ) {
        SecureSettingsStore.saveString(firstName, forKey: SettingsUI.firstNameKey, defaults: defaults, passwordStore: passwordStore)
        SecureSettingsStore.saveString(lastName, forKey: SettingsUI.lastNameKey, defaults: defaults, passwordStore: passwordStore)

        // Derive the username from the user's initials (first letter of first and last name).
        let firstInitial = firstName.first.map { String($0).uppercased() } ?? ""
        let lastInitial = lastName.first.map { String($0).uppercased() } ?? ""
        defaults.set(firstInitial + lastInitial, forKey: SettingsUI.usernameKey)
        SecureSettingsStore.saveString(email, forKey: SettingsUI.emailKey, defaults: defaults, passwordStore: passwordStore)
        SecureSettingsStore.saveString(phoneNumber, forKey: SettingsUI.phoneKey, defaults: defaults, passwordStore: passwordStore)
        SecureSettingsStore.removeString(forKey: SettingsUI.legacyPasswordKey, defaults: defaults, passwordStore: passwordStore)
    }

    func loginUsingTouchId() {
        guard !isProcessing else { return }
        guard loginService.currentUserId != nil else {
            loginStatusMessage = "Sign in with email and password before using Face ID."
            return
        }

        authTask?.cancel()
        authTask = Task { [weak self] in
            guard let self else { return }
            isProcessing = true
            defer { isProcessing = false }

            do {
                let success = try await authenticationService.authenticateUsingTouchId()
                guard !Task.isCancelled else { return }
                guard success else {
                    loginStatusMessage = "Biometric authentication was not completed."
                    return
                }

                guard loginService.currentUserId != nil else {
                    loginStatusMessage = "Your session expired. Sign in with email and password."
                    return
                }

                isAuthenticated = true
                didCompleteLoginProcess()
            } catch is CancellationError {
                return
            } catch {
                loginStatusMessage = error.localizedDescription
            }
        }
    }

    private func loginUser() async {
        do {
            let uid = try await loginService.signIn(email: email, password: password)
            guard !Task.isCancelled else { return }
            let settings = try await loginService.fetchUserSettings(userId: uid)
            guard !Task.isCancelled else { return }
            updateSettings(
                firstName: settings.firstName,
                lastName: settings.lastName,
                email: settings.email.isEmpty ? email : settings.email,
                phoneNumber: settings.phoneNumber
            )
            loginStatusMessage = "Successfully logged in user: \(uid)"
            didCompleteLoginProcess()
        } catch is CancellationError {
            return
        } catch {
            loginStatusMessage = "Failed to login user: \(error.localizedDescription)"
        }
    }

    private func createNewAccount() async {
        let imageData = image.flatMap { ImagePreprocessor.prepareForUpload($0, maxDimension: 1024, targetMaxBytes: 200_000, initialQuality: 0.75) }
        guard let imageData else {
            loginStatusMessage = "You must select an avatar image"
            return
        }

        do {
            let uid = try await loginService.createUser(email: email, password: password)
            guard !Task.isCancelled else { return }
            loginStatusMessage = "Successfully created user: \(uid)"

            let imageURL = try await loginService.uploadProfileImage(imageData, userId: uid)
            guard !Task.isCancelled else { return }
            loginStatusMessage = "Successfully stored image with url: \(imageURL.absoluteString)"

            try await loginService.storeUserInformation(
                email: email,
                userId: uid,
                firstName: firstName,
                lastName: lastName,
                phoneNumber: phoneNumber,
                profileImageURL: imageURL
            )
            guard !Task.isCancelled else { return }
            updateSettings(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phoneNumber: phoneNumber
            )
            try await loginService.sendEmailVerification()
            guard !Task.isCancelled else { return }
            loginStatusMessage = "Successfully created account. Check your email to verify your address."
            didCompleteLoginProcess()
        } catch is CancellationError {
            return
        } catch {
            loginStatusMessage = "Failed to create account: \(error.localizedDescription)"
        }
    }
}

