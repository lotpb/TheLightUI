//
//  MainMessagesView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

import SwiftUI
import SDWebImageSwiftUI

struct MainMessagesView: View {
    let isAuthenticated: Bool
    let onSignOut: () -> Void

    private let makeChatRepository: () -> ChatRepositoryProtocol
    
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowNewMessageScreen = false
    @State private var chatUser: UserModel?
    
    @StateObject private var vm: MainMessagesViewModel
    @StateObject private var chatLogViewModel: ChatLogViewModel

    init(
        isAuthenticated: Bool,
        onSignOut: @escaping () -> Void,
        repository: ChatRepositoryProtocol = FirebaseChatRepository(),
        chatLogRepository: ChatRepositoryProtocol = FirebaseChatRepository(),
        makeChatRepository: @escaping () -> ChatRepositoryProtocol = { FirebaseChatRepository() }
    ) {
        self.isAuthenticated = isAuthenticated
        self.onSignOut = onSignOut
        self.makeChatRepository = makeChatRepository
        _vm = StateObject(wrappedValue: MainMessagesViewModel(repository: repository))
        _chatLogViewModel = StateObject(
            wrappedValue: ChatLogViewModel(chatUser: nil, repository: chatLogRepository)
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                InboxBackground()

                VStack(spacing: 0) {
                    customNavBar
                    messagesView
                }

                newMessageButton
            }
            .overlay(alignment: .top) { errorBanner }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $shouldNavigateToChatLogView) {
                ChatLogView(vm: chatLogViewModel)
            }
        }
        .onAppear(perform: updateForAuthenticationState)
        .onChange(of: isAuthenticated) { _ in
            updateForAuthenticationState()
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 14) {
            CurrentUserAvatar(urlString: vm.chatUser?.profileImageUrl)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName(for: vm.chatUser?.email) ?? "Messages")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    Text("Online")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()

            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .confirmationDialog("Settings", isPresented: $shouldShowLogOutOptions, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                vm.clearSessionData()
                onSignOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("What do you want to do?")
        }
    }
    
    private var messagesView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                inboxHeader

                if vm.recentMessages.isEmpty {
                    EmptyInboxView()
                        .padding(.top, 44)
                } else {
                    ForEach(vm.recentMessages) { recentMessage in
                        Button {
                            openChat(for: recentMessage)
                        } label: {
                            RecentMessageRow(recentMessage: recentMessage)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 108)
        }
    }

    private var inboxHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Inbox")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Recent conversations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(vm.recentMessages.count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.blue, in: Capsule())
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            Label("New", systemImage: "square.and.pencil")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(Color.blue, in: Capsule())
                .shadow(color: .blue.opacity(0.28), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(
                didSelectNewUser: { user in
                    self.shouldNavigateToChatLogView.toggle()
                    self.chatUser = user
                    self.chatLogViewModel.chatUser = user
                    self.chatLogViewModel.fetchMessages()
                },
                repository: makeChatRepository()
            )
        }
    }

    private var errorBanner: some View {
        Group {
            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.92), in: Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
        }
    }

    private func updateForAuthenticationState() {
        if isAuthenticated {
            vm.refreshForActiveSession()
        } else {
            vm.clearSessionData()
        }
    }

    private func openChat(for recentMessage: RecentMessage) {
        chatUser = vm.chatUser(for: recentMessage)
        chatLogViewModel.chatUser = chatUser
        chatLogViewModel.fetchMessages()
        shouldNavigateToChatLogView.toggle()
    }

    private func displayName(for email: String?) -> String? {
        email//?.replacingOccurrences(of: "@optonline.net", with: "")
    }
}

private struct InboxBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct CurrentUserAvatar: View {
    let urlString: String?

    var body: some View {
        ProfileAvatarImage(urlString: urlString)
            .frame(width: 52, height: 52)
            .background(Color(.tertiarySystemFill))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}

private struct RecentMessageRow: View {
    let recentMessage: RecentMessage

    private var displayName: String {
        recentMessage.email//.replacingOccurrences(of: "@optonline.net", with: "")
    }

    var body: some View {
        HStack(spacing: 14) {
            ProfileAvatarImage(urlString: recentMessage.profileImageUrl)
                .frame(width: 45, height: 45)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayName)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(recentMessage.daysAndHoursAgoText + " Ago")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(recentMessage.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
    }
}

private struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 70, height: 70)
                .background(.regularMaterial, in: Circle())

            VStack(spacing: 4) {
                Text("No conversations yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Start a new message to begin chatting.")
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

#Preview("Main Messages") {
    MainMessagesView(isAuthenticated: true, onSignOut: { })
        .preferredColorScheme(.dark)
}
