//
//  LoginViewModel.swift
//  TheLightUI
//

import Foundation
import UIKit

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isLoginMode = true
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    @Published var password = ""
    @Published var image: UIImage?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isProcessing = false
    @Published var loginStatusMessage = ""

    private let loginService: LoginServicing
    private let authenticationService: AuthenticationService
    private let didCompleteLoginProcess: () -> Void
    private let defaults: UserDefaults
    private let passwordStore: PasswordStoring

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

    func handlePrimaryAction() {
        guard !isProcessing else { return }

        Task {
            isProcessing = true
            defer { isProcessing = false }

            if isLoginMode {
                await loginUser()
            } else {
                await createNewAccount()
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
        phoneNumber: String,
        password: String
    ) {
        defaults.set(firstName, forKey: SettingsUI.firstNameKey)
        defaults.set(lastName, forKey: SettingsUI.lastNameKey)
        defaults.set(email, forKey: SettingsUI.emailKey)
        defaults.set(phoneNumber, forKey: SettingsUI.phoneKey)
        passwordStore.savePassword(password, for: SettingsUI.passwordKey)
    }

    func loginUsingTouchId() {
        guard !isProcessing else { return }

        Task {
            isProcessing = true
            defer { isProcessing = false }

            do {
                let success = try await authenticationService.authenticateUsingTouchId()
                if success {
                    isAuthenticated = true
                    didCompleteLoginProcess()
                }
            } catch {
                loginStatusMessage = error.localizedDescription
            }
        }
    }

    private func loginUser() async {
        do {
            let uid = try await loginService.signIn(email: email, password: password)
            let settings = try await loginService.fetchUserSettings(userId: uid)
            updateSettings(
                firstName: settings.firstName,
                lastName: settings.lastName,
                email: settings.email.isEmpty ? email : settings.email,
                phoneNumber: settings.phoneNumber,
                password: password
            )
            loginStatusMessage = "Successfully logged in user: \(uid)"
            didCompleteLoginProcess()
        } catch {
            loginStatusMessage = "Failed to login user: \(error.localizedDescription)"
        }
    }

    private func createNewAccount() async {
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else {
            loginStatusMessage = "You must select an avatar image"
            return
        }

        do {
            let uid = try await loginService.createUser(email: email, password: password)
            loginStatusMessage = "Successfully created user: \(uid)"

            let imageURL = try await loginService.uploadProfileImage(imageData, userId: uid)
            loginStatusMessage = "Successfully stored image with url: \(imageURL.absoluteString)"

            try await loginService.storeUserInformation(
                email: email,
                userId: uid,
                firstName: firstName,
                lastName: lastName,
                phoneNumber: phoneNumber,
                profileImageURL: imageURL
            )
            updateSettings(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phoneNumber: phoneNumber,
                password: password
            )
            didCompleteLoginProcess()
        } catch {
            loginStatusMessage = "Failed to create account: \(error.localizedDescription)"
        }
    }
}
