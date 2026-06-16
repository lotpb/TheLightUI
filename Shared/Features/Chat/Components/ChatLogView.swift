//
//  ChatLogView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/26/21.
//

import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct ChatLogView: View {
    
    private enum Layout {
        static let tabBarHeight: CGFloat = 62
        static let messageBarBottomPadding = tabBarHeight
    }

    @ObservedObject var vm: ChatLogViewModel
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isPickingPhoto = false
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            ChatBackground()
            messagesView
            errorBanner
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChatNavigationTitle(user: vm.chatUser)
            }
        }
        .onAppear {
            vm.fetchMessages()
        }
        .onDisappear {
            vm.stopListening()
        }
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if vm.chatMessages.isEmpty {
                        EmptyChatView()
                            .padding(.top, 120)
                    }

                    ForEach(vm.chatMessages.indices, id: \.self) { index in
                        let message = vm.chatMessages[index]

                        MessageView(
                            message: message,
                            currentUserId: vm.currentUserId,
                            showsTimestamp: shouldShowTimestamp(at: index)
                        )
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.emptyScrollToString)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
            .id(vm.chatUser?.uid ?? "empty-chat")
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .padding(.bottom, messageBarBottomPadding)
            }
            .onAppear {
                scrollToBottom(using: scrollViewProxy, animated: false)
            }
            .onChange(of: vm.chatMessages.count) { _ in
                scrollToBottom(using: scrollViewProxy, animated: true)
            }
        }
    }
    
    private var messageBarBottomPadding: CGFloat {
        isMessageFieldFocused ? 0 : Layout.messageBarBottomPadding
    }

    private func shouldShowTimestamp(at index: Int) -> Bool {
        guard index > 0 else { return true }

        let previousMessage = vm.chatMessages[index - 1]
        let currentMessage = vm.chatMessages[index]
        return !Calendar.current.isDate(previousMessage.timestamp, inSameDayAs: currentMessage.timestamp)
    }

    private func scrollToBottom(using scrollViewProxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.35)) {
                    scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                }
            } else {
                scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
            }
        }
    }
    
    private var chatBottomBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            photoPickerButton

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $vm.chatText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .focused($isMessageFieldFocused)
                    .submitLabel(.send)
                    .onSubmit(submitMessage)
                    .padding(.vertical, 10)

                sendButton
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var photoPickerButton: some View {
        let isUploadingImage = vm.isUploadingImage

        return PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .automatic) {
            Image(systemName: isUploadingImage ? "arrow.triangle.2.circlepath" : "photo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(.regularMaterial, in: Circle())
        }
        .disabled(isUploadingImage)
        .onChange(of: selectedPhoto) { newValue in
            guard let newValue = newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    vm.handleSendImage(data)
                    await MainActor.run { selectedPhoto = nil }
                }
            }
        }
    }

    private func submitMessage() {
        guard !vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        vm.handleSend()
        isMessageFieldFocused = false
    }

    private var sendButton: some View {
        let canSend = !vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return Button {
            submitMessage()
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(canSend ? Color.blue : Color(.systemGray4), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .padding(.bottom, 5)
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private struct ChatBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct ChatNavigationTitle: View {
    let user: UserModel?

    private var displayName: String {
        user?.email.replacingOccurrences(of: "@optonline.net", with: "") ?? "Chat"
    }

    var body: some View {
        HStack(spacing: 10) {
            profileImage

            VStack(alignment: .leading, spacing: 1) {
                Text(displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Active now")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var profileImage: some View {
        ProfileAvatarImage(urlString: user?.profileImageUrl)
            .frame(width: 32, height: 32)
            .clipShape(Circle())
    }
}

private struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 68, height: 68)
                .background(.regularMaterial, in: Circle())

            VStack(spacing: 4) {
                Text("No messages yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Send a message or photo to start the conversation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

struct MessageView: View {
    let message: ChatMessage
    let currentUserId: String?
    let showsTimestamp: Bool

    private var isCurrentUserMessage: Bool {
        message.fromId == currentUserId
    }

    private var imageURL: URL? {
        guard message.messageType == .image || isLegacyFirebaseStorageImageMessage else { return nil }
        guard let url = URL(string: message.text), url.scheme == "https" else { return nil }
        return url
    }

    private var isLegacyFirebaseStorageImageMessage: Bool {
        guard let url = URL(string: message.text), url.scheme == "https" else { return false }
        guard url.host?.contains("firebasestorage.googleapis.com") == true else { return false }
        return url.absoluteString.contains("chat_images")
    }

    var body: some View {
        VStack(alignment: isCurrentUserMessage ? .trailing : .leading, spacing: 4) {
            HStack(alignment: .bottom) {
                if isCurrentUserMessage { Spacer(minLength: 48) }

                messageBubble

                if !isCurrentUserMessage { Spacer(minLength: 48) }
            }

            if showsTimestamp {
                Text(message.sentDateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 8)
            }
        }
    }

    private var messageBubble: some View {
        VStack(alignment: isCurrentUserMessage ? .trailing : .leading, spacing: 0) {
            if let imageURL {
                WebImage(url: imageURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 230, height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isCurrentUserMessage ? .white : .primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
        .background(bubbleBackground)
        .clipShape(ChatBubble(isCurrentUserMessage: isCurrentUserMessage))
        .shadow(color: .black.opacity(isCurrentUserMessage ? 0.08 : 0.04), radius: 10, x: 0, y: 4)
    }

    private var bubbleBackground: Color {
        isCurrentUserMessage ? .blue : Color(.secondarySystemGroupedBackground)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock chat user for preview
        let mockUser = UserModel(uid: "6787g8fghctrdcrt6", email: "arp1@gmail.com", profileImageUrl: "profile-rabbit-toy.png")
        let vm = ChatLogViewModel(chatUser: mockUser)
        return Group {
            NavigationView {
                ChatLogView(vm: vm)
            }
            //.preferredColorScheme(.light)

            NavigationView {
                ChatLogView(vm: vm)
            }
            .preferredColorScheme(.dark)
        }
    }
}
