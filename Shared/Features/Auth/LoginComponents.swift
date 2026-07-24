//
//  LoginComponents.swift
//  TheLightUI (iOS)
//

import SwiftUI

// MARK: - Field identifier

enum LoginField: Hashable {
    case firstName
    case lastName
    case phoneNumber
    case email
    case password
}

// MARK: - Avatar

struct AvatarView: View {
    let image: UIImage?

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: LoginView.Layout.avatarSize, height: LoginView.Layout.avatarSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: LoginView.Layout.avatarPlaceholderSize, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: LoginView.Layout.avatarSize, height: LoginView.Layout.avatarSize)
                .background(Color(.tertiarySystemGroupedBackground), in: Circle())
        }
    }
}

// MARK: - Text field

struct LoginTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var textInputAutocapitalization: TextInputAutocapitalization? = .sentences
    var focusedField: FocusState<LoginField?>.Binding
    let field: LoginField

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .submitLabel(.next)
                .focused(focusedField, equals: field)
        }
        .loginFieldStyle(isFocused: focusedField.wrappedValue == field)
    }
}

// MARK: - Secure field

struct LoginSecureField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var focusedField: FocusState<LoginField?>.Binding
    let field: LoginField

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            SecureField(title, text: $text)
                .textContentType(.password)
                .submitLabel(.go)
                .focused(focusedField, equals: field)
        }
        .loginFieldStyle(isFocused: focusedField.wrappedValue == field)
    }
}

// MARK: - Field style

extension View {
    func loginFieldStyle(isFocused: Bool) -> some View {
        self
            .padding(LoginView.Layout.fieldPadding)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: LoginView.Layout.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LoginView.Layout.cornerRadius, style: .continuous)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
            .foregroundStyle(Color.primary)
    }
}
