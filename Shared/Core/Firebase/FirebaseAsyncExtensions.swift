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
        try await withCheckedThrowingContinuation { continuation in
            signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let uid = result?.user.uid, !uid.isEmpty else {
                    continuation.resume(throwing: missingUserIdError)
                    return
                }

                continuation.resume(returning: uid)
            }
        }
    }

    func createUserIdAsync(
        email: String,
        password: String,
        missingUserIdError: Error = FirebaseAsyncError.missingUserId
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let uid = result?.user.uid, !uid.isEmpty else {
                    continuation.resume(throwing: missingUserIdError)
                    return
                }

                continuation.resume(returning: uid)
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: missingSnapshotError)
                }
            }
        }
    }
}

extension DocumentReference {
    func getDocumentAsync(
        missingSnapshotError: Error = FirebaseAsyncError.missingDocumentSnapshot
    ) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: missingSnapshotError)
                }
            }
        }
    }

    func setDataAsync(_ data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func deleteAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension WriteBatch {
    func commitAsync() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            commit { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension StorageReference {
    func uploadDataAsync(_ data: Data, metadata: StorageMetadata? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
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
