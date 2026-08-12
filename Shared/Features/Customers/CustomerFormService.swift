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
    // One-time migration: stamps companyId on records written before multi-tenancy.
    // Safe to call repeatedly — exits immediately once already migrated.
    func migrateCompanyId() async throws
}

// `@unchecked Sendable`: holds FirebaseManager.shared, which is itself
// @unchecked Sendable and thread-safe by Firebase contract.
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

    func migrateCompanyId() async throws {
        let key = "com.thelight.companyIdMigrationV1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        guard let companyId = CompanySession.companyId, !companyId.isEmpty,
              let userId = currentUserId else { return }

        try await migrateCompanyIdPage(
            companyId: companyId,
            userId: userId,
            after: nil
        )

        UserDefaults.standard.set(true, forKey: key)
    }

    // Fetches up to 500 documents per page for this userId, writes a batch
    // update for any that are missing companyId, then recurses with a cursor
    // until all pages have been processed.
    private func migrateCompanyIdPage(
        companyId: String,
        userId: String,
        after lastDoc: DocumentSnapshot?
    ) async throws {
        let col = manager.firestore.collection(CustomerFirestoreSchema.collection)
        var query = col
            .whereField(CustomerFirestoreSchema.Field.uid, isEqualTo: userId)
            .limit(to: 500)
        if let lastDoc {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        guard !snapshot.documents.isEmpty else { return }

        // Filter client-side: documents missing the field or with an empty value.
        let unmigrated = snapshot.documents.filter { doc in
            let existing = doc.get(CustomerFirestoreSchema.Field.companyId) as? String ?? ""
            return existing.isEmpty
        }

        if !unmigrated.isEmpty {
            let batch = manager.firestore.batch()
            for doc in unmigrated {
                batch.updateData(
                    [CustomerFirestoreSchema.Field.companyId: companyId],
                    forDocument: doc.reference
                )
            }
            try await batch.commit()
        }

        // If a full page was returned there may be more; recurse with cursor.
        if snapshot.documents.count == 500 {
            try await migrateCompanyIdPage(
                companyId: companyId,
                userId: userId,
                after: snapshot.documents.last
            )
        }
    }
}
