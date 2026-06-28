//
//  CreateNewMessageView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/22/21.
//

import SwiftUI
import SDWebImageSwiftUI

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (UserModel) -> Void
    private let maxWidthForIpad: CGFloat = 700
    
    @Environment(\.dismiss) private var dismiss
    @State private var vm: CreateNewMessageViewModel
    @State private var searchText = ""

    init(
        didSelectNewUser: @escaping (UserModel) -> Void,
        repository: ChatRepositoryProtocol = FirebaseChatRepository()
    ) {
        self.didSelectNewUser = didSelectNewUser
        _vm = State(initialValue: CreateNewMessageViewModel(repository: repository))
    }

    private var filteredUsers: [UserModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return vm.users }
        return vm.users.filter { $0.email.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                NewMessageBackground()
                content
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .frame(maxWidth: maxWidthForIpad)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                header
                searchField
                errorBanner

                if filteredUsers.isEmpty {
                    EmptyNewMessageView(hasSearchText: !searchText.isEmpty)
                        .padding(.top, 28)
                } else {
                    usersList
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New Message")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Choose someone to start a conversation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search people", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color(.separator).opacity(0.14), lineWidth: 1))
    }

    @ViewBuilder
    private var errorBanner: some View {
        if !vm.errorMessage.isEmpty {
            Text(vm.errorMessage)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var usersList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredUsers) { user in
                Button {
                    dismiss()
                    didSelectNewUser(user)
                } label: {
                    NewMessageUserRow(user: user)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Cancel") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
        }
    }
}

private struct NewMessageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct NewMessageUserRow: View {
    let user: UserModel

    private var displayName: String {
        user.email//.replacingOccurrences(of: "@optonline.net", with: "")
    }

    var body: some View {
        HStack(spacing: 14) {
            ProfileAvatarImage(urlString: user.profileImageUrl)
                .frame(width: 54, height: 54)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(user.email)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
    }
}

private struct EmptyNewMessageView: View {
    let hasSearchText: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: hasSearchText ? "person.crop.circle.badge.questionmark" : "person.2.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 70, height: 70)
                .background(.regularMaterial, in: Circle())

            VStack(spacing: 4) {
                Text(hasSearchText ? "No people found" : "No contacts available")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(hasSearchText ? "Try a different search." : "New users will appear here when they are available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

#Preview("Create New Message") {
    CreateNewMessageView { _ in }
        .preferredColorScheme(.dark)
}
