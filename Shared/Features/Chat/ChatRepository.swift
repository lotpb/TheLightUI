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
    func fetchUser(uid: String) async throws -> UserModel
    func fetchAvailableUsers() async throws -> [UserModel]
    func listenForRecentMessages(
        userId: String,
        onChange: @escaping ([RecentMessage]) -> Void,
        onRemoved: @escaping ([String]) -> Void,
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

// `@unchecked Sendable`: wraps Firebase's ListenerRegistration, which is
// thread-safe by contract but lacks Sendable conformance in the SDK.
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
            .getDocument()

        let user = try snapshot.data(as: UserModel.self)

        manager.currentUser = user
        return user
    }

    func fetchUser(uid: String) async throws -> UserModel {
        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .document(uid)
            .getDocument()
        return try snapshot.data(as: UserModel.self)
    }

    func fetchAvailableUsers() async throws -> [UserModel] {
        guard let companyId = CompanySession.companyId, !companyId.isEmpty else {
            return []
        }
        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()

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
        onRemoved: @escaping ([String]) -> Void,
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

                var upserted: [RecentMessage] = []
                var removedIds: [String] = []
                for change in querySnapshot?.documentChanges ?? [] {
                    switch change.type {
                    case .added, .modified:
                        if let message = try? change.document.data(as: RecentMessage.self) {
                            upserted.append(message)
                        }
                    case .removed:
                        removedIds.append(change.document.documentID)
                    @unknown default:
                        break
                    }
                }
                if !upserted.isEmpty { onChange(upserted) }
                if !removedIds.isEmpty { onRemoved(removedIds) }
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

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadedURL = try await storageRef.downloadURL()
        guard downloadedURL.scheme == "https" else {
            throw ChatRepositoryError.invalidImageURL
        }

        try await sendMessage(
            text: downloadedURL.absoluteString,
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
            firstName: chatUser.firstName,
            lastName: chatUser.lastName,
            timestamp: timestamp
        )
        let recipientRecentData = makeRecentMessageData(
            text: recentMessageText,
            fromId: fromId,
            toId: chatUser.uid,
            profileImageUrl: senderUser.profileImageUrl,
            email: senderUser.email,
            firstName: senderUser.firstName,
            lastName: senderUser.lastName,
            timestamp: timestamp
        )

        let batch = manager.firestore.batch()
        batch.setData(messageData, forDocument: senderDocument)
        batch.setData(messageData, forDocument: recipientDocument)
        batch.setData(senderRecentData, forDocument: senderRecentDocument)
        batch.setData(recipientRecentData, forDocument: recipientRecentDocument)

        try await batch.commit()
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
        firstName: String?,
        lastName: String?,
        timestamp: Timestamp
    ) -> [String: Any] {
        var data: [String: Any] = [
            FirebaseConstants.timestamp: timestamp,
            FirebaseConstants.text: text,
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: profileImageUrl,
            FirebaseConstants.email: email
        ]
        if let firstName { data[FirebaseConstants.firstName] = firstName }
        if let lastName  { data[FirebaseConstants.lastName]  = lastName  }
        return data
    }

}

enum ChatRepositoryError: LocalizedError {
    case missingCurrentUser
    case invalidImageURL

    var errorDescription: String? {
        switch self {
        case .missingCurrentUser:
            return "Could not find the current user."
        case .invalidImageURL:
            return "The image URL returned by Storage is not a valid HTTPS URL."
        }
    }
}

// MARK: - Local JSON

private struct NoOpChatListener: ChatListener {
    func remove() {}
}

/// Reads recent messages from Documents/MessagesBackup.json.
/// Used when "Store Data on Device" is enabled in Settings.
final class LocalJSONChatRepository: ChatRepositoryProtocol, Sendable {
    static let fileName = "MessagesBackup.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    var currentUserId: String? { "local-user" }

    func signOut() throws {}

    func fetchCurrentUser() async throws -> UserModel {
        let email = SecureSettingsStore.loadString(forKey: SettingsUI.emailKey)
        return UserModel(uid: "local-user", email: email.isEmpty ? "local@device" : email, profileImageUrl: "")
    }

    func fetchUser(uid: String) async throws -> UserModel {
        try await fetchCurrentUser()
    }

    func fetchAvailableUsers() async throws -> [UserModel] { [] }

    func listenForRecentMessages(
        userId: String,
        onChange: @escaping ([RecentMessage]) -> Void,
        onRemoved: @escaping ([String]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        // Both closures are only ever called back on DispatchQueue.main, so
        // boxing them as @unchecked Sendable is safe.
        struct Box<T>: @unchecked Sendable { let fn: T }
        let onChangeBox = Box(fn: onChange)
        let onErrorBox  = Box(fn: onError)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: Self.fileURL)
                let records = try MessageJSONTransfer.decodeRecords(from: data)
                let messages = records.map(\.recentMessage)
                DispatchQueue.main.async { onChangeBox.fn(messages) }
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError {
                    DispatchQueue.main.async { onChangeBox.fn([]) }
                } else {
                    DispatchQueue.main.async { onErrorBox.fn(error) }
                }
            }
        }
        return NoOpChatListener()
    }

    func listenForMessages(
        fromId: String,
        toId: String,
        onMessages: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        onMessages([])
        return NoOpChatListener()
    }

    func sendTextMessage(_ text: String, to chatUser: UserModel) async throws {}
    func sendImageMessage(_ imageData: Data, to chatUser: UserModel) async throws {}
}
