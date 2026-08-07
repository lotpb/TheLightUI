//
//  ToDoFirestore.swift
//  TheLightUI
//

// Firestore schema constants, item mapping, and the backup/restore
// service for the ToDoItems collection.

import Foundation
import FirebaseFirestore

enum ToDoFirestoreSchema {
    static let collection = "ToDoItems"

    enum Field {
        static let title = "title"
        static let notes = "notes"
        static let isCompleted = "isCompleted"
        static let position = "position"
        static let lastUpdate = "lastUpdate"
        static let createdAt = "createdAt"
    }
}

extension ItemModel {
    init(document: QueryDocumentSnapshot) {
        let fields = ToDoFirestoreSchema.Field.self
        let createdAtTimestamp = document.get(fields.createdAt) as? Timestamp
        self.init(
            id: document.documentID,
            title: document.get(fields.title) as? String ?? "",
            notes: document.get(fields.notes) as? String ?? "",
            isCompleted: document.get(fields.isCompleted) as? Bool ?? false,
            createdAt: createdAtTimestamp?.dateValue() ?? Date()
        )
    }

    /// Data written on every Firestore write. companyId is omitted when
    /// CompanySession has no value (e.g. account has no custom claim yet).
    func firestoreData(position: Int) -> [String: Any] {
        var data: [String: Any] = [
            ToDoFirestoreSchema.Field.title: title,
            ToDoFirestoreSchema.Field.notes: notes,
            ToDoFirestoreSchema.Field.isCompleted: isCompleted,
            ToDoFirestoreSchema.Field.position: position,
            ToDoFirestoreSchema.Field.lastUpdate: Timestamp(date: Date()),
            ToDoFirestoreSchema.Field.createdAt: Timestamp(date: createdAt)
        ]
        if let companyId = CompanySession.companyId { data["companyId"] = companyId }
        return data
    }
}

// `@unchecked Sendable`: holds a Firestore reference, which is thread-safe
// by Firebase contract but lacks Sendable conformance in the SDK.
final class ToDoFirestoreService: @unchecked Sendable {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    /// Uploads every item, overwriting documents with the same id so the
    /// backup always reflects the current local state. Refreshes the auth
    /// token first so companyId and rule checks are always current.
    func backUp(_ items: [ItemModel]) async throws {
        await CompanySession.refresh()
        let collection = firestore.collection(ToDoFirestoreSchema.collection)

        // Firestore caps a write batch at 500 operations.
        for start in stride(from: 0, to: items.count, by: 500) {
            let batch = firestore.batch()
            for (offset, item) in items[start..<min(start + 500, items.count)].enumerated() {
                batch.setData(item.firestoreData(position: start + offset), forDocument: collection.document(item.id))
            }
            try await batch.commit()
        }
    }

    /// Overwrites only this account's documents to match the given items,
    /// deleting docs for items that no longer exist locally. Scoped to
    /// companyId so it never touches another account's documents.
    func replaceAll(_ items: [ItemModel]) async throws {
        guard let companyId = CompanySession.companyId else { return }
        let collection = firestore.collection(ToDoFirestoreSchema.collection)
        // Only consider docs that belong to this company to avoid deleting
        // another account's items that share the same collection.
        let existingIDs = try await collection
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments().documents.map(\.documentID)
        let keptIDs = Set(items.map(\.id))

        // Deletions first, then upserts, chunked at Firestore's 500-write cap.
        var operations: [(id: String, data: [String: Any]?)] = existingIDs
            .filter { !keptIDs.contains($0) }
            .map { ($0, nil) }
        operations += items.enumerated().map { ($1.id, $1.firestoreData(position: $0)) }

        for start in stride(from: 0, to: operations.count, by: 500) {
            let batch = firestore.batch()
            for operation in operations[start..<min(start + 500, operations.count)] {
                let document = collection.document(operation.id)
                if let data = operation.data {
                    batch.setData(data, forDocument: document)
                } else {
                    batch.deleteDocument(document)
                }
            }
            try await batch.commit()
        }
    }

    /// Fetches only this account's items from Firestore, sorted by creation date.
    func fetchAll() async throws -> [ItemModel] {
        guard let companyId = CompanySession.companyId else { return [] }
        let snapshot = try await firestore.collection(ToDoFirestoreSchema.collection)
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()
        return snapshot.documents
            .map(ItemModel.init)
            .sorted { $0.createdAt < $1.createdAt }
    }
}
