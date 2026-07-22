//
//  CustomerFormService.swift
//  TheLightUI
//

import Foundation
import FirebaseFirestore

protocol CustomerFormServicing: Sendable {
    var currentUserId: String? { get }
    func addCustomer(_ payload: CustomerFormPayload) async throws -> String
    func updateCustomer(id: String, payload: CustomerFormPayload) async throws
    // Commits every entry in one atomic batch (callers must respect
    // Firestore's 500-writes-per-batch limit). Entries with an empty id
    // create new documents; the rest overwrite the document with that id.
    func upsertCustomersBatch(_ entries: [(id: String, payload: CustomerFormPayload)]) async throws
}

final class FirebaseCustomerFormService: CustomerFormServicing, @unchecked Sendable {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
    }

    func addCustomer(_ payload: CustomerFormPayload) async throws -> String {
        try await manager.firestore
            .collection(CustomerFirestoreSchema.collection)
            .addDocument(data: payload.firestoreData)
            .documentID
    }

    func updateCustomer(id: String, payload: CustomerFormPayload) async throws {
        try await manager.firestore
            .collection(CustomerFirestoreSchema.collection)
            .document(id)
            .setData(payload.firestoreData)
    }

    func upsertCustomersBatch(_ entries: [(id: String, payload: CustomerFormPayload)]) async throws {
        let collection = manager.firestore.collection(CustomerFirestoreSchema.collection)
        let batch = manager.firestore.batch()
        for entry in entries {
            let document = entry.id.isEmpty ? collection.document() : collection.document(entry.id)
            batch.setData(entry.payload.firestoreData, forDocument: document)
        }
        try await batch.commit()
    }
}
