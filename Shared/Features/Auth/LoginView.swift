//
//  LoginView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 10/26/21.
//

import PhotosUI
import SwiftUI
import CoreLocation

// MARK: - Login
struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var focusedField: LoginField?
    private let locationCaptureManager: LocationCaptureManaging
    private let loginService: LoginServicing

    enum Layout {
        static let maxContentWidth: CGFloat = 520
        static let contentSpacing: CGFloat = 18
        static let sectionSpacing: CGFloat = 24
        static let avatarSize: CGFloat = 116
        static let avatarPlaceholderSize: CGFloat = 42
        static let fieldPadding: CGFloat = 14
        static let buttonHeight: CGFloat = 48
        static let cornerRadius: CGFloat = 8
    }

    init(
        loginService: LoginServicing = FirebaseLoginService(),
        authenticationService: AuthenticationService = AuthenticationService(),
        locationCaptureManager: LocationCaptureManaging = LocationCaptureManager(),
        didCompleteLoginProcess: @escaping () -> Void
    ) {
        self.locationCaptureManager = locationCaptureManager
        self.loginService = loginService
        _viewModel = State(
            initialValue: LoginViewModel(
                loginService: loginService,
                authenticationService: authenticationService,
                didCompleteLoginProcess: didCompleteLoginProcess
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    header
                    formContent
                }
                .frame(maxWidth: Layout.maxContentWidth)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onChange(of: viewModel.loginStatusMessage) { _, newValue in
                guard newValue.localizedCaseInsensitiveContains("success") else { return }
                // Unstructured Task so the capture survives the login cover
                // being dismissed by didCompleteLoginProcess.
                Task { await captureLoginLocation() }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedProfilePhoto()
        }
    }

    // MARK: - Content

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: viewModel.isLoginMode ? "lock.shield.fill" : "person.crop.circle.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 56, height: 56)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))

            Text(viewModel.navigationTitle)
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text(viewModel.isLoginMode ? "Access your account with email, password, or Face ID." : "Add your profile details to create a new account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formContent: some View {
        VStack(spacing: Layout.contentSpacing) {
            modePicker
            if !viewModel.isLoginMode {
                profilePhotoPicker
                accountFields
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            credentialsFields
            actionButtons
            statusMessage
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .animation(.snappy, value: viewModel.isLoginMode)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $viewModel.isLoginMode) {
            Text("Login").tag(true)
            Text("Create").tag(false)
        }
        .pickerStyle(.segmented)
        .disabled(viewModel.isProcessing)
    }

    private var profilePhotoPicker: some View {
        let image = viewModel.image
        let title = image == nil ? "Choose Profile Photo" : "Change Profile Photo"

        return PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            VStack(spacing: 10) {
                AvatarView(image: image)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.blue, in: Circle())
                            .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 3))
                    }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .accessibilityLabel(title)
    }

    private var accountFields: some View {
        VStack(spacing: 12) {
            LoginTextField(
                title: "First Name",
                systemImage: "person.text.rectangle",
                text: $viewModel.firstName,
                textContentType: .givenName,
                focusedField: $focusedField,
                field: .firstName
            )
            LoginTextField(
                title: "Last Name",
                systemImage: "person.text.rectangle.fill",
                text: $viewModel.lastName,
                textContentType: .familyName,
                focusedField: $focusedField,
                field: .lastName
            )
            LoginTextField(
                title: "Phone Number",
                systemImage: "phone.fill",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad,
                textContentType: .telephoneNumber,
                focusedField: $focusedField,
                field: .phoneNumber
            )
            .onChange(of: viewModel.phoneNumber) { _, newValue in
                viewModel.formatPhoneNumber(newValue)
            }
        }
        .disabled(viewModel.isProcessing)
    }

    private var credentialsFields: some View {
        VStack(spacing: 12) {
            LoginTextField(
                title: "Email",
                systemImage: "envelope.fill",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                textInputAutocapitalization: .never,
                focusedField: $focusedField,
                field: .email
            )
            .autocorrectionDisabled()
            LoginSecureField(
                title: "Password",
                systemImage: "key.fill",
                text: $viewModel.password,
                focusedField: $focusedField,
                field: .password
            )
        }
        .disabled(viewModel.isProcessing)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.handlePrimaryAction) {
                HStack(spacing: 10) {
                    if viewModel.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: viewModel.isLoginMode ? "arrow.right.circle.fill" : "person.badge.plus.fill")
                    }
                    Text(viewModel.isProcessing ? "Working" : viewModel.primaryActionTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Layout.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Layout.cornerRadius))
            .disabled(viewModel.isProcessing)

            if viewModel.isLoginMode {
                Button(action: viewModel.sendPasswordReset) {
                    Label("Reset Password", systemImage: "envelope.badge")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: Layout.buttonHeight)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: Layout.cornerRadius))
                .disabled(viewModel.isProcessing)
            }

            Button(action: viewModel.loginUsingTouchId) {
                Label("Sign in with Face ID", systemImage: "faceid")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: Layout.buttonHeight)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: Layout.cornerRadius))
            .disabled(viewModel.isProcessing)
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var statusMessage: some View {
        if !viewModel.loginStatusMessage.isEmpty {
            Label(viewModel.loginStatusMessage, systemImage: statusIcon)
                .font(.footnote)
                .foregroundStyle(statusColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
                .accessibilityIdentifier("loginStatusMessage")

            let savedLat = SecureSettingsStore.loadString(forKey: SettingsUI.latitudeKey)
            let savedLon = SecureSettingsStore.loadString(forKey: SettingsUI.longitudeKey)
            if !savedLat.isEmpty || !savedLon.isEmpty {
                Text("Lat: \(savedLat)  Lon: \(savedLon)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var statusColor: Color {
        viewModel.loginStatusMessage.localizedCaseInsensitiveContains("success") ? .green : .red
    }

    private var statusIcon: String {
        viewModel.loginStatusMessage.localizedCaseInsensitiveContains("success") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    // MARK: - Helpers

    private func loadSelectedProfilePhoto() async {
        guard let selectedPhotoItem else { return }
        do {
            guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: imageData) else {
                viewModel.loginStatusMessage = "Could not load the selected photo."
                return
            }
            viewModel.image = image
            viewModel.loginStatusMessage = ""
        } catch {
            viewModel.loginStatusMessage = "Could not load the selected photo: \(error.localizedDescription)"
        }
    }

    private func captureLoginLocation() async {
        guard let coordinate = await locationCaptureManager.requestSingleLocation() else { return }
        SecureSettingsStore.saveString(String(coordinate.latitude), forKey: SettingsUI.latitudeKey)
        SecureSettingsStore.saveString(String(coordinate.longitude), forKey: SettingsUI.longitudeKey)
        guard let userId = loginService.currentUserId else { return }
        try? await loginService.updateUserLocation(
            userId: userId,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

// MARK: - Preview
#Preview("Login - Dark") {
    LoginView(didCompleteLoginProcess: { })
        .preferredColorScheme(.dark)
}
