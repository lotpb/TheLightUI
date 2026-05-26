//
//  LoginView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 10/26/21.
//

import SwiftUI

// MARK: - Login
struct LoginView: View {
    @Environment(\.openURL) private var openURL

    fileprivate enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let contentSpacing: CGFloat = 16
        static let avatarSize: CGFloat = 128
        static let avatarPlaceholderSize: CGFloat = 64
        static let avatarBorderWidth: CGFloat = 3
        static let fieldPadding: CGFloat = 12
        static let buttonHeight: CGFloat = 30
    }

    let didCompleteLoginProcess: () -> Void

    @State private var isLoginMode = true
    @State private var email = "eunited@aol.net"
    @State private var password = "united"
    @State private var shouldShowImagePicker = false
    @State private var image: UIImage?
    @State private var isAuthenticated = false
    @State private var loginStatusMessage = ""

    private var navigationTitle: String {
        isLoginMode ? "Log In" : "Create Account"
    }

    var body: some View {
        NavigationStack {
            loginContent
                .navigationTitle(navigationTitle)
                .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }
        .frame(maxWidth: Layout.maxContentWidth)
    }

    // MARK: - Content

    private var loginContent: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: Layout.contentSpacing) {
                modePicker

                if !isLoginMode {
                    profileImageButton
                }

                credentialsFields
                actionButtons
                statusMessage
            }
            .padding()
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $isLoginMode) {
            Text("Login")
                .tag(true)
            Text("Create Account")
                .tag(false)
        }
        .pickerStyle(.segmented)
    }

    private var profileImageButton: some View {
        Button {
            shouldShowImagePicker.toggle()
        } label: {
            avatarContent
                .overlay(Circle().stroke(Color.primary, lineWidth: Layout.avatarBorderWidth))
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: Layout.avatarPlaceholderSize))
                .padding()
                .foregroundColor(.primary)
        }
    }

    private var credentialsFields: some View {
        Group {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
        }
        .loginFieldStyle()
    }

    private var primaryActionButton: some View {
        Button(action: handlePrimaryAction) {
            fullWidthButtonLabel(isLoginMode ? "Log In" : "Create Account", color: .blue)
        }
    }

    private var biometricLoginButton: some View {
        Button(action: loginUsingTouchId) {
            fullWidthButtonLabel("Sign in with Face ID", color: .orange)
        }
    }

    private var touchIDButton: some View {
        HStack {
            Spacer()
            Button(action: loginUsingTouchId) {
                Image(systemName: "touchid")
            }
        }
    }

    private var statusMessage: some View {
        Text(loginStatusMessage)
            .foregroundColor(.red)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            primaryActionButton
            biometricLoginButton
            touchIDButton
        }
        .padding(.top, 25)
    }

    private func fullWidthButtonLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, minHeight: Layout.buttonHeight)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }

    private func loginUsingTouchId() {
        AuthenticationService().authenticateUsingTouchId { success, error in
            if success {
                isAuthenticated = true
                didCompleteLoginProcess()
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }

    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, error in
            if let error {
                print("failed to login user:", error)
                loginStatusMessage = "Failed to login user: \(error)"
                return
            }

            let uid = result?.user.uid ?? ""
            print("Successfully logged in user: \(uid)")
            loginStatusMessage = "Successfully logged in user: \(uid)"
            didCompleteLoginProcess()
        }
    }

    private func createNewAccount() {
        guard image != nil else {
            loginStatusMessage = "You must select an avatar image"
            return
        }

        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, error in
            if let error {
                print("failed to create user:", error)
                loginStatusMessage = "Failed to create user: \(error)"
                return
            }

            let uid = result?.user.uid ?? ""
            print("Successfully created user: \(uid)")
            loginStatusMessage = "Successfully created user: \(uid)"
            persistImageToStorage()
        }
    }

    // MARK: - Persistence

    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else { return }

        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        ref.putData(imageData, metadata: nil) { result in
            switch result {
            case .success:
                ref.downloadURL { url, error in
                    handleProfileImageURL(url, error: error)
                }
            case .failure(let error):
                loginStatusMessage = "Failed to push image to Storage: \(error)"
            }
        }
    }

    private func handleProfileImageURL(_ url: URL?, error: Error?) {
        if let error {
            loginStatusMessage = "Failed to retrieve downloadURL: \(error)"
            return
        }

        guard let url else { return }
        loginStatusMessage = "Successfully stored image with url: \(url.absoluteString)"
        print(url.absoluteString)
        storeUserInformation(imageProfileUrl: url)
    }

    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        let userData = [
            FirebaseConstants.email: email,
            FirebaseConstants.uid: uid,
            FirebaseConstants.profileImageUrl: imageProfileUrl.absoluteString
        ]

        FirebaseManager.shared.firestore.collection(FirebaseConstants.users)
            .document(uid)
            .setData(userData) { error in
                if let error {
                    loginStatusMessage = "\(error)"
                    return
                }

                print("Success")
                didCompleteLoginProcess()
            }
    }
}

// MARK: - Styles
private extension View {
    func loginFieldStyle() -> some View {
        self
            .padding(LoginView.Layout.fieldPadding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
            .foregroundColor(.primary)
    }
}

// MARK: - Preview
#Preview("Login - Dark") {
    LoginView(didCompleteLoginProcess: { })
        .preferredColorScheme(.dark)
}
