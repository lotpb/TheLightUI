//
//  MainMessagesViewModel.swift
//  TheLightUI
//

import Foundation

@MainActor
final class MainMessagesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var chatUser: UserModel?
    @Published var recentMessages = [RecentMessage]()

    private let repository: ChatRepositoryProtocol
    private var chatListener: ChatListener?
    private var refreshTask: Task<Void, Never>?
    private var listenerGeneration = UUID()

    var currentUserId: String? {
        repository.currentUserId
    }

    init(repository: ChatRepositoryProtocol = FirebaseChatRepository()) {
        self.repository = repository
    }

    deinit {
        refreshTask?.cancel()
        chatListener?.remove()
    }

    func fetchRecentMessages() {
        guard let uid = repository.currentUserId else { return }

        chatListener?.remove()
        recentMessages.removeAll()
        listenerGeneration = UUID()
        let generation = listenerGeneration

        chatListener = repository.listenForRecentMessages(
            userId: uid,
            onChange: { [weak self] messages in
                Task { @MainActor [weak self] in
                    guard let self, self.listenerGeneration == generation else { return }
                    for recentMessage in messages {
                        if let index = recentMessages.firstIndex(where: { $0.id == recentMessage.id }) {
                            recentMessages.remove(at: index)
                        }
                        recentMessages.insert(recentMessage, at: 0)
                    }
                }
            },
            onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.listenerGeneration == generation else { return }
                    errorMessage = "Failed to listen for recent messages: \(error.localizedDescription)"
                }
            }
        )
    }

    func refreshForActiveSession() {
        refreshTask?.cancel()

        guard repository.currentUserId != nil else {
            clearSessionData()
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else { return }
            await fetchCurrentUser()
            guard !Task.isCancelled else { return }
            fetchRecentMessages()
        }
    }

    func fetchCurrentUser() async {
        guard repository.currentUserId != nil else { return }

        do {
            chatUser = try await repository.fetchCurrentUser()
        } catch {
            errorMessage = "Failed to fetch current user: \(error.localizedDescription)"
        }
    }

    func clearSessionData() {
        refreshTask?.cancel()
        refreshTask = nil
        listenerGeneration = UUID()
        chatListener?.remove()
        chatListener = nil
        chatUser = nil
        recentMessages.removeAll()
    }

    func chatUser(for recentMessage: RecentMessage) -> UserModel {
        let uid = currentUserId == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
        return UserModel(id: uid, uid: uid, email: recentMessage.email, profileImageUrl: recentMessage.profileImageUrl)
    }
}
