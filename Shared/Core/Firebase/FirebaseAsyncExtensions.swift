//
//  FirebaseAsyncExtensions.swift
//  TheLightUI
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum FirebaseAsyncError: LocalizedError {
    case missingUserId
    case missingDocumentId
    case missingDocumentSnapshot
    case missingQuerySnapshot
    case missingDownloadURL

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "Could not find the authenticated user ID."
        case .missingDocumentId:
            return "Could not read the document ID."
        case .missingDocumentSnapshot:
            return "Firestore returned an empty document snapshot."
        case .missingQuerySnapshot:
            return "Firestore returned an empty query snapshot."
        case .missingDownloadURL:
            return "Could not create a download URL."
        }
    }
}

extension Auth {
    func signInUserIdAsync(
        email: String,
        password: String,
        missingUserIdError: Error = FirebaseAsyncError.missingUserId
    ) async throws -> String {
        let result = try await signIn(withEmail: email, password: password)
        let uid = result.user.uid
        guard !uid.isEmpty else { throw missingUserIdError }
        return uid
    }

    func createUserIdAsync(
        email: String,
        password: String,
        missingUserIdError: Error = FirebaseAsyncError.missingUserId
    ) async throws -> String {
        let result = try await createUser(withEmail: email, password: password)
        let uid = result.user.uid
        guard !uid.isEmpty else { throw missingUserIdError }
        return uid
    }

    func sendPasswordResetAsync(email: String) async throws {
        try await sendPasswordReset(withEmail: email)
    }
}

extension User {
    func sendEmailVerificationAsync() async throws {
        try await sendEmailVerification()
    }
}

extension CollectionReference {
    func addDocumentAsync(
        data: [String: Any],
        missingDocumentIdError: Error = FirebaseAsyncError.missingDocumentId
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var reference: DocumentReference?
            reference = addDocument(data: data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let documentId = reference?.documentID {
                    continuation.resume(returning: documentId)
                } else {
                    continuation.resume(throwing: missingDocumentIdError)
                }
            }
        }
    }

    func getDocumentsAsync(
        missingSnapshotError: Error = FirebaseAsyncError.missingQuerySnapshot
    ) async throws -> QuerySnapshot {
        let snapshot = try await getDocuments()
        return snapshot
    }
}

extension DocumentReference {
    func getDocumentAsync(
        missingSnapshotError: Error = FirebaseAsyncError.missingDocumentSnapshot
    ) async throws -> DocumentSnapshot {
        let snapshot = try await getDocument()
        return snapshot
    }

    func setDataAsync(_ data: [String: Any]) async throws {
        try await setData(data)
    }

    func deleteAsync() async throws {
        try await delete()
    }
}

extension WriteBatch {
    func commitAsync() async throws {
        try await commit()
    }
}

extension StorageReference {
    func uploadDataAsync(_ data: Data, metadata: StorageMetadata? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func downloadURLAsync(
        missingURLError: Error = FirebaseAsyncError.missingDownloadURL
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: missingURLError)
                }
            }
        }
    }
}

