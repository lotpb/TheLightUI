//
//  LoginService.swift
//  TheLightUI
//

import Foundation

protocol LoginServicing {
    func signIn(email: String, password: String) async throws -> String
    func createUser(email: String, password: String) async throws -> String
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL
    func storeUserInformation(email: String, userId: String, profileImageURL: URL) async throws
}

final class FirebaseLoginService: LoginServicing {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func signIn(email: String, password: String) async throws -> String {
        try await manager.auth.signInUserIdAsync(
            email: email,
            password: password,
            missingUserIdError: LoginServiceError.missingUserId
        )
    }

    func createUser(email: String, password: String) async throws -> String {
        try await manager.auth.createUserIdAsync(
            email: email,
            password: password,
            missingUserIdError: LoginServiceError.missingUserId
        )
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL {
        let ref = manager.storage.reference(withPath: userId)
        try await ref.uploadDataAsync(imageData)
        return try await ref.downloadURLAsync(missingURLError: LoginServiceError.missingProfileImageURL)
    }

    func storeUserInformation(email: String, userId: String, profileImageURL: URL) async throws {
        let userData = [
            FirebaseConstants.email: email,
            FirebaseConstants.uid: userId,
            FirebaseConstants.profileImageUrl: profileImageURL.absoluteString
        ]

        try await manager.firestore.collection(FirebaseConstants.users)
            .document(userId)
            .setDataAsync(userData)
    }
}

enum LoginServiceError: LocalizedError {
    case missingUserId
    case missingProfileImageURL

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "Could not find the authenticated user ID."
        case .missingProfileImageURL:
            return "Could not create a URL for the selected profile image."
        }
    }
}
