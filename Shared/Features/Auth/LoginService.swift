//
//  LoginService.swift
//  TheLightUI
//

import Foundation

struct LoginUserSettings {
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String
}

protocol LoginServicing: Sendable {
    var currentUserId: String? { get }

    func signIn(email: String, password: String) async throws -> String
    func createUser(email: String, password: String) async throws -> String
    func sendPasswordReset(email: String) async throws
    func sendEmailVerification() async throws
    func fetchUserSettings(userId: String) async throws -> LoginUserSettings
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL
    func storeUserInformation(
        email: String,
        userId: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        profileImageURL: URL
    ) async throws
}

final class FirebaseLoginService: LoginServicing {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
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

    func sendPasswordReset(email: String) async throws {
        try await manager.auth.sendPasswordResetAsync(email: email)
    }

    func sendEmailVerification() async throws {
        guard let user = manager.auth.currentUser else {
            throw LoginServiceError.missingCurrentUser
        }

        try await user.sendEmailVerificationAsync()
    }

    func fetchUserSettings(userId: String) async throws -> LoginUserSettings {
        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .document(userId)
            .getDocumentAsync()

        return LoginUserSettings(
            firstName: snapshot.get(FirebaseConstants.firstName) as? String ?? "",
            lastName: snapshot.get(FirebaseConstants.lastName) as? String ?? "",
            email: snapshot.get(FirebaseConstants.email) as? String ?? "",
            phoneNumber: snapshot.get(FirebaseConstants.phone) as? String ?? ""
        )
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL {
        let ref = manager.storage.reference(withPath: userId)
        try await ref.uploadDataAsync(imageData)
        return try await ref.downloadURLAsync(missingURLError: LoginServiceError.missingProfileImageURL)
    }

    func storeUserInformation(
        email: String,
        userId: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        profileImageURL: URL
    ) async throws {
        let userData = [
            FirebaseConstants.email: email,
            FirebaseConstants.uid: userId,
            FirebaseConstants.firstName: firstName,
            FirebaseConstants.lastName: lastName,
            FirebaseConstants.phone: phoneNumber,
            FirebaseConstants.profileImageUrl: profileImageURL.absoluteString
        ]

        try await manager.firestore.collection(FirebaseConstants.users)
            .document(userId)
            .setDataAsync(userData)
    }
}

enum LoginServiceError: LocalizedError {
    case missingUserId
    case missingCurrentUser
    case missingProfileImageURL

    var errorDescription: String? {
        switch self {
        case .missingUserId, .missingCurrentUser:
            return "Could not find the authenticated user."
        case .missingProfileImageURL:
            return "Could not create a URL for the selected profile image."
        }
    }
}
