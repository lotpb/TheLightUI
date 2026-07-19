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
        try validate(firstName: firstName, lastName: lastName, email: email, phoneNumber: phoneNumber)

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
        guard (-90...90).contains(latitude) else {
            throw LoginServiceError.invalidLatitude
        }
        guard (-180...180).contains(longitude) else {
            throw LoginServiceError.invalidLongitude
        }

        try await manager.firestore.collection(FirebaseConstants.users)
            .document(userId)
            .setData([
                FirebaseConstants.latitude: latitude,
                FirebaseConstants.longitude: longitude
            ], merge: true)
    }

    // MARK: Private validation

    private func validate(
        firstName: String,
        lastName: String,
        email: String,
        phoneNumber: String
    ) throws {
        guard !firstName.isEmpty else {
            throw LoginServiceError.emptyFirstName
        }
        guard firstName.count <= 100 else {
            throw LoginServiceError.fieldTooLong("First name", limit: 100)
        }
        guard lastName.count <= 100 else {
            throw LoginServiceError.fieldTooLong("Last name", limit: 100)
        }
        guard !email.isEmpty, email.contains("@") else {
            throw LoginServiceError.invalidEmail
        }
        guard email.count <= 254 else {
            throw LoginServiceError.fieldTooLong("Email", limit: 254)
        }
        guard phoneNumber.count <= 20 else {
            throw LoginServiceError.fieldTooLong("Phone number", limit: 20)
        }
    }
}

enum LoginServiceError: LocalizedError {
    case missingCurrentUser
    case emptyFirstName
    case invalidEmail
    case fieldTooLong(String, limit: Int)
    case invalidLatitude
    case invalidLongitude

    var errorDescription: String? {
        switch self {
        case .missingCurrentUser:
            "Could not find the authenticated user."
        case .emptyFirstName:
            "First name is required."
        case .invalidEmail:
            "Please enter a valid email address."
        case .fieldTooLong(let field, let limit):
            "\(field) must be \(limit) characters or fewer."
        case .invalidLatitude:
            "Latitude must be between -90 and 90."
        case .invalidLongitude:
            "Longitude must be between -180 and 180."
        }
    }
}
