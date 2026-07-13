//
//  LoginService.swift
//  TheLightUI
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
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
    func updateUserLocation(userId: String, latitude: Double, longitude: Double) async throws
}

struct FirebaseLoginService: LoginServicing {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        try await manager.auth.signIn(withEmail: email, password: password).user.uid
    }

    func createUser(email: String, password: String) async throws -> String {
        try await manager.auth.createUser(withEmail: email, password: password).user.uid
    }

    func sendPasswordReset(email: String) async throws {
        try await manager.auth.sendPasswordReset(withEmail: email)
    }

    func sendEmailVerification() async throws {
        guard let user = manager.auth.currentUser else {
            throw LoginServiceError.missingCurrentUser
        }

        try await user.sendEmailVerification()
    }

    func fetchUserSettings(userId: String) async throws -> LoginUserSettings {
        let snapshot = try await manager.firestore
            .collection(FirebaseConstants.users)
            .document(userId)
            .getDocument()

        return LoginUserSettings(
            firstName: snapshot.get(FirebaseConstants.firstName) as? String ?? "",
            lastName: snapshot.get(FirebaseConstants.lastName) as? String ?? "",
            email: snapshot.get(FirebaseConstants.email) as? String ?? "",
            phoneNumber: snapshot.get(FirebaseConstants.phone) as? String ?? ""
        )
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL {
        let ref = manager.storage.reference(withPath: userId)
        _ = try await ref.putDataAsync(imageData)
        return try await ref.downloadURL()
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
            .setData(userData)
    }

    func updateUserLocation(userId: String, latitude: Double, longitude: Double) async throws {
        try await manager.firestore.collection(FirebaseConstants.users)
            .document(userId)
            .setData([
                FirebaseConstants.latitude: latitude,
                FirebaseConstants.longitude: longitude
            ], merge: true)
    }
}

enum LoginServiceError: LocalizedError {
    case missingCurrentUser

    var errorDescription: String? {
        switch self {
        case .missingCurrentUser:
            "Could not find the authenticated user."
        }
    }
}

