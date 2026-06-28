//
//  ChatLogViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class ChatLogViewModel {
    var chatText = ""
    var errorMessage = ""
    var chatMessages = [ChatMessage]()
    var isUploadingImage = false

    var chatUser: UserModel?

    @ObservationIgnored private let repository: ChatRepositoryProtocol
    @ObservationIgnored private var chatListener: ChatListener?
    @ObservationIgnored private var listenerGeneration = UUID()
    @ObservationIgnored private var sendTask: Task<Void, Never>?
    @ObservationIgnored private var uploadTask: Task<Void, Never>?

    var currentUserId: String? {
        repository.currentUserId
    }

    init(chatUser: UserModel?, repository: ChatRepositoryProtocol = FirebaseChatRepository()) {
        self.chatUser = chatUser
        self.repository = repository
    }

    deinit {
        sendTask?.cancel()
        uploadTask?.cancel()
        chatListener?.remove()
    }

    func stopListening() {
        listenerGeneration = UUID()
        chatListener?.remove()
        chatListener = nil
    }

    func fetchMessages() {
        guard let fromId = repository.currentUserId else { return }
        guard let toId = chatUser?.uid else { return }

        stopListening()
        chatMessages.removeAll()
        listenerGeneration = UUID()
        let generation = listenerGeneration

        chatListener = repository.listenForMessages(
            fromId: fromId,
            toId: toId,
            onMessages: { [weak self] newMessages in
                Task { @MainActor [weak self] in
                    guard let self, self.listenerGeneration == generation else { return }
                    chatMessages.append(contentsOf: newMessages)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.listenerGeneration == generation else { return }
                    errorMessage = "Failed to listen for messages: \(error.localizedDescription)"
                }
            }
        )
    }

    func handleSendImage(_ imageData: Data) {
        guard let chatUser else { return }

        uploadTask?.cancel()
        uploadTask = Task { [weak self] in
            guard let self else { return }
            isUploadingImage = true
            defer { isUploadingImage = false }

            do {
                try await repository.sendImageMessage(imageData, to: chatUser)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
            }
        }
    }

    func handleSend() {
        let draftText = chatText
        let messageText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        guard let chatUser else { return }

        chatText = ""

        sendTask?.cancel()
        sendTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.sendTextMessage(messageText, to: chatUser)
            } catch is CancellationError {
                return
            } catch {
                if chatText.isEmpty {
                    chatText = draftText
                }
                errorMessage = "Failed to save message: \(error.localizedDescription)"
            }
        }
    }
}
