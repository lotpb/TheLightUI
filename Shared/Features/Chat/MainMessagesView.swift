//
//  MainMessagesView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

// Main messages screen showing inbox, navigation to chats, and new message flow.

import SwiftUI
import SDWebImageSwiftUI

/// MainMessagesView
/// Displays the inbox for the current user with a custom nav bar, recent conversations list,
/// and a floating button to start new messages. Handles authentication state and navigation
/// into a specific chat log.
struct MainMessagesView: View {
    // Whether the user is currently signed in.
    let isAuthenticated: Bool
    // Callback to trigger sign-out from a parent coordinator.
    let onSignOut: () -> Void

    // Factory for repositories used by child views (CreateNewMessageView).
    private let makeChatRepository: () -> ChatRepositoryProtocol
    
    private enum Layout {
        static let tabBarHeight: CGFloat = 62
        static let floatingButtonTabBarSpacing: CGFloat = 20
        static let floatingButtonBottomPadding = tabBarHeight + floatingButtonTabBarSpacing
        static let messagesBottomPadding: CGFloat = 148
    }

    // UI state for dialogs/navigation and sheet presentation.
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowNewMessageScreen = false
    // The selected chat user for the chat log.
    @State private var chatUser: UserModel?
    
    // View models: inbox (vm) and active chat log.
    @StateObject private var vm: MainMessagesViewModel
    @StateObject private var chatLogViewModel: ChatLogViewModel

    // Inject dependencies and initialize view models.
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
            // Main layered layout: background, content, and floating action button.
            ZStack(alignment: .bottomTrailing) {
                InboxBackground()

                VStack(spacing: 0) {
                    // Custom navigation bar with current user and settings.
                    customNavBar
                    // Recent messages list / empty state.
                    messagesView
                }

                // Floating action to start a new conversation.
                newMessageButton
            }
            .overlay(alignment: .top) { errorBanner }
            // Transient error banner shown at the top.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            // Let content extend under the keyboard for smoother transitions.
            .navigationBarHidden(true)
            // Programmatic navigation into the chat log when a conversation is opened.
            .navigationDestination(isPresented: $shouldNavigateToChatLogView) {
                ChatLogView(vm: chatLogViewModel)
            }
        }
        // Refresh or clear inbox based on authentication when the view appears.
        .onAppear(perform: updateForAuthenticationState)
        // React to auth state changes while the view is on-screen.
        .onChange(of: isAuthenticated) { _ in
            updateForAuthenticationState()
        }
    }
    
    // Top bar showing the current user's avatar, name, presence, and settings.
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

            // Settings button opens a confirmation dialog for sign out.
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
        // Confirmation dialog for signing out.
        .confirmationDialog("Settings", isPresented: $shouldShowLogOutOptions, titleVisibility: .visible) {
            // Clear any local session state and notify parent to sign out.
            Button("Sign Out", role: .destructive) {
                vm.clearSessionData()
                onSignOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("What do you want to do?")
        }
    }
    
    // Scrollable inbox with recent conversations or an empty state.
    private var messagesView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                // Section header: title and count of conversations.
                inboxHeader

                if vm.recentMessages.isEmpty {
                    EmptyInboxView()
                        .padding(.top, 44)
                } else {
                    ForEach(vm.recentMessages) { recentMessage in
                        Button {
                            openChat(for: recentMessage)
                        } label: {
                            RecentMessageRow(
                                recentMessage: recentMessage,
                                relativeTo: vm.relativeTimeReferenceDate
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, Layout.messagesBottomPadding)
        }
        .refreshable {
            await vm.refreshInbox()
        }
    }

    // Section header: title and count of conversations.
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
    
    // Floating "New" button that presents the user picker full screen.
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
        .padding(.bottom, Layout.floatingButtonBottomPadding)
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            // When a user is selected, navigate to the chat log and start fetching messages.
            CreateNewMessageView(
                didSelectNewUser: { user in
                    self.shouldNavigateToChatLogView.toggle()
                    self.chatUser = user
                    self.chatLogViewModel.chatUser = user
                },
                repository: makeChatRepository()
            )
        }
    }

    // Top-aligned banner that shows transient error messages from the view model.
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

    // Keep inbox state consistent with authentication.
    private func updateForAuthenticationState() {
        if isAuthenticated {
            vm.refreshForActiveSession()
        } else {
            vm.clearSessionData()
        }
    }

    // Compute chat user from a recent message and navigate to the chat log.
    private func openChat(for recentMessage: RecentMessage) {
        chatUser = vm.chatUser(for: recentMessage)
        chatLogViewModel.chatUser = chatUser
        shouldNavigateToChatLogView.toggle()
    }

    // Display name derived from email (customize as needed).
    private func displayName(for email: String?) -> String? {
        email//?.replacingOccurrences(of: "@optonline.net", with: "")
    }
}

// Subview: gradient background behind the inbox.
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

// Subview: current user's avatar with styling.
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

// Subview: a single row representing a recent conversation.
private struct RecentMessageRow: View {
    let recentMessage: RecentMessage
    let relativeTo: Date

    // Name to display for the conversation partner.
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

                    Text(recentMessage.daysAndHoursAgoText(relativeTo: relativeTo) + " Ago")
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

// Subview: empty state when there are no conversations yet.
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

// Preview: main messages screen.
#Preview("Main Messages") {
    MainMessagesView(isAuthenticated: true, onSignOut: { })
        .preferredColorScheme(.dark)
}
