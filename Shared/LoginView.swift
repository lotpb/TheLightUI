//
//  LoginView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 10/26/21.
//

import SwiftUI

// MARK: - Login
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    fileprivate enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let contentSpacing: CGFloat = 16
        static let avatarSize: CGFloat = 128
        static let avatarPlaceholderSize: CGFloat = 64
        static let avatarBorderWidth: CGFloat = 3
        static let fieldPadding: CGFloat = 12
        static let buttonHeight: CGFloat = 30
    }

    init(
        loginService: LoginServicing = FirebaseLoginService(),
        authenticationService: AuthenticationService = AuthenticationService(),
        didCompleteLoginProcess: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(
                loginService: loginService,
                authenticationService: authenticationService,
                didCompleteLoginProcess: didCompleteLoginProcess
            )
        )
    }

    var body: some View {
        NavigationStack {
            loginContent
                .navigationTitle(viewModel.navigationTitle)
                .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $viewModel.shouldShowImagePicker) {
            ImagePicker(image: $viewModel.image)
        }
        .frame(maxWidth: Layout.maxContentWidth)
    }

    // MARK: - Content

    private var loginContent: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: Layout.contentSpacing) {
                modePicker

                if !viewModel.isLoginMode {
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
        Picker("Mode", selection: $viewModel.isLoginMode) {
            Text("Login")
                .tag(true)
            Text("Create Account")
                .tag(false)
        }
        .pickerStyle(.segmented)
    }

    private var profileImageButton: some View {
        Button {
            viewModel.shouldShowImagePicker.toggle()
        } label: {
            avatarContent
                .overlay(Circle().stroke(Color.primary, lineWidth: Layout.avatarBorderWidth))
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let image = viewModel.image {
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
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Password", text: $viewModel.password)
        }
        .loginFieldStyle()
    }

    private var primaryActionButton: some View {
        Button(action: viewModel.handlePrimaryAction) {
            fullWidthButtonLabel(viewModel.primaryActionTitle, color: .blue)
        }
    }

    private var biometricLoginButton: some View {
        Button(action: viewModel.loginUsingTouchId) {
            fullWidthButtonLabel("Sign in with Face ID", color: .orange)
        }
    }

    private var touchIDButton: some View {
        HStack {
            Spacer()
            Button(action: viewModel.loginUsingTouchId) {
                Image(systemName: "touchid")
            }
        }
    }

    private var statusMessage: some View {
        Text(viewModel.loginStatusMessage)
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
