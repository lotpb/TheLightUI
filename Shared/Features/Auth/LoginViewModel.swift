//
//  LoginViewModel.swift
//  TheLightUI
//

import Foundation
import UIKit

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isLoginMode = true
    @Published var email = ""
    @Published var password = ""
    @Published var shouldShowImagePicker = false
    @Published var image: UIImage?
    @Published private(set) var isAuthenticated = false
    @Published var loginStatusMessage = ""

    private let loginService: LoginServicing
    private let authenticationService: AuthenticationService
    private let didCompleteLoginProcess: () -> Void

    var navigationTitle: String {
        isLoginMode ? "Log In" : "Create Account"
    }

    var primaryActionTitle: String {
        isLoginMode ? "Log In" : "Create Account"
    }

    init(
        loginService: LoginServicing = FirebaseLoginService(),
        authenticationService: AuthenticationService = AuthenticationService(),
        didCompleteLoginProcess: @escaping () -> Void
    ) {
        self.loginService = loginService
        self.authenticationService = authenticationService
        self.didCompleteLoginProcess = didCompleteLoginProcess
    }

    func handlePrimaryAction() {
        Task {
            if isLoginMode {
                await loginUser()
            } else {
                await createNewAccount()
            }
        }
    }

    func loginUsingTouchId() {
        Task {
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

            try await loginService.storeUserInformation(email: email, userId: uid, profileImageURL: imageURL)
            didCompleteLoginProcess()
        } catch {
            loginStatusMessage = "Failed to create account: \(error.localizedDescription)"
        }
    }
}
