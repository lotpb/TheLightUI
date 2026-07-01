//
//  ChatRepository.swift
//  TheLightUI
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

protocol ChatListener: Sendable {
    func remove()
}

protocol ChatRepositoryProtocol: Sendable {
    var currentUserId: String? { get }

    func signOut() throws
    func fetchCurrentUser() async throws -> UserModel
    func fetchAvailableUsers() async throws -> [UserModel]
    func listenForRecentMessages(
        userId: String,
        onChange: @escaping ([RecentMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener
    func listenForMessages(
        fromId: String,
        toId: String,
        onMessages: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener
    func sendTextMessage(_ text: String, to chatUser: UserModel) async throws
    func sendImageMessage(_ imageData: Data, to chatUser: UserModel) async throws
}

final class FirebaseChatListener: ChatListener, @unchecked Sendable {
    private let registration: ListenerRegistration

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration.remove()
    }
}

final class FirebaseChatRepository: ChatRepositoryProtocol {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
    }

    func signOut() throws {
        try manager.auth.signOut()
    }

    func fetchCurrentUser() async throws -> UserModel {
        guard let uid = currentUserId else {
            throw ChatRepositoryError.missingCurrentUser
        }

        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .document(uid)
            .getDocumentAsync(missingSnapshotError: ChatRepositoryError.userNotFound)

        let user = try snapshot.data(as: UserModel.self)

        manager.currentUser = user
        return user
    }

    func fetchAvailableUsers() async throws -> [UserModel] {
        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .getDocumentsAsync(missingSnapshotError: ChatRepositoryError.emptySnapshot)

        return snapshot.documents.compactMap { snapshot -> UserModel? in
            guard let user = try? snapshot.data(as: UserModel.self), user.uid != currentUserId else {
                return nil
            }
            return user
        }
    }

    func listenForRecentMessages(
        userId: String,
        onChange: @escaping ([RecentMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        let registration = manager.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(userId)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    onError(error)
                    return
                }

                let messages = querySnapshot?.documentChanges.compactMap { change -> RecentMessage? in
                    try? change.document.data(as: RecentMessage.self)
                } ?? []
                onChange(messages)
            }

        return FirebaseChatListener(registration: registration)
    }

    func listenForMessages(
        fromId: String,
        toId: String,
        onMessages: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        let registration = manager.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    onError(error)
                    return
                }

                let newMessages = querySnapshot?.documentChanges.compactMap { change -> ChatMessage? in
                    guard change.type == .added else { return nil }
                    return try? change.document.data(as: ChatMessage.self)
                } ?? []
                onMessages(newMessages)
            }

        return FirebaseChatListener(registration: registration)
    }

    func sendTextMessage(_ text: String, to chatUser: UserModel) async throws {
        guard let fromId = currentUserId else {
            throw ChatRepositoryError.missingCurrentUser
        }

        try await sendMessage(
            text: text,
            recentMessageText: text,
            messageType: .text,
            fromId: fromId,
            to: chatUser
        )
    }

    func sendImageMessage(_ imageData: Data, to chatUser: UserModel) async throws {
        guard let fromId = currentUserId else {
            throw ChatRepositoryError.missingCurrentUser
        }

        let fileName = UUID().uuidString + ".jpg"
        let storageRef = manager.storage.reference(withPath: "chat_images/\(fromId)/\(chatUser.uid)/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await storageRef.uploadDataAsync(imageData, metadata: metadata)
        let imageURL = try await storageRef.downloadURLAsync(
            missingURLError: ChatRepositoryError.missingImageURL
        ).absoluteString

        try await sendMessage(
            text: imageURL,
            recentMessageText: "Photo",
            messageType: .image,
            fromId: fromId,
            to: chatUser
        )
    }

    private func sendMessage(
        text: String,
        recentMessageText: String,
        messageType: ChatMessageType,
        fromId: String,
        to chatUser: UserModel
    ) async throws {
        let senderUser = try await cachedCurrentUser()
        let timestamp = Timestamp()
        let messageData: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: chatUser.uid,
            FirebaseConstants.text: text,
            FirebaseConstants.messageType: messageType.rawValue,
            FirebaseConstants.timestamp: timestamp
        ]

        let messageId = manager.firestore.collection(FirebaseConstants.messages).document().documentID
        let senderDocument = manager.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(chatUser.uid)
            .document(messageId)

        let recipientDocument = manager.firestore
            .collection(FirebaseConstants.messages)
            .document(chatUser.uid)
            .collection(fromId)
            .document(messageId)

        let senderRecentDocument = manager.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(fromId)
            .collection(FirebaseConstants.messages)
            .document(chatUser.uid)

        let recipientRecentDocument = manager.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(chatUser.uid)
            .collection(FirebaseConstants.messages)
            .document(fromId)

        let senderRecentData = makeRecentMessageData(
            text: recentMessageText,
            fromId: fromId,
            toId: chatUser.uid,
            profileImageUrl: chatUser.profileImageUrl,
            email: chatUser.email,
            timestamp: timestamp
        )
        let recipientRecentData = makeRecentMessageData(
            text: recentMessageText,
            fromId: fromId,
            toId: chatUser.uid,
            profileImageUrl: senderUser.profileImageUrl,
            email: senderUser.email,
            timestamp: timestamp
        )

        let batch = manager.firestore.batch()
        batch.setData(messageData, forDocument: senderDocument)
        batch.setData(messageData, forDocument: recipientDocument)
        batch.setData(senderRecentData, forDocument: senderRecentDocument)
        batch.setData(recipientRecentData, forDocument: recipientRecentDocument)

        try await batch.commitAsync()
    }

    private func cachedCurrentUser() async throws -> UserModel {
        if let currentUser = manager.currentUser {
            return currentUser
        }

        return try await fetchCurrentUser()
    }

    private func makeRecentMessageData(
        text: String,
        fromId: String,
        toId: String,
        profileImageUrl: String,
        email: String,
        timestamp: Timestamp
    ) -> [String: Any] {
        [
            FirebaseConstants.timestamp: timestamp,
            FirebaseConstants.text: text,
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: profileImageUrl,
            FirebaseConstants.email: email
        ]
    }

}

enum ChatRepositoryError: LocalizedError {
    case missingCurrentUser
    case userNotFound
    case missingImageURL
    case emptySnapshot

    var errorDescription: String? {
        switch self {
        case .missingCurrentUser:
            return "Could not find the current user."
        case .userNotFound:
            return "Could not load the current user profile."
        case .missingImageURL:
            return "Could not create a download URL for the selected image."
        case .emptySnapshot:
            return "Firestore returned an empty snapshot."
        }
    }
}
