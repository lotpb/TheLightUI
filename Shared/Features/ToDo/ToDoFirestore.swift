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
    }
}

extension ItemModel {
    init(document: QueryDocumentSnapshot) {
        let fields = ToDoFirestoreSchema.Field.self
        self.init(
            id: document.documentID,
            title: document.get(fields.title) as? String ?? "",
            notes: document.get(fields.notes) as? String ?? "",
            isCompleted: document.get(fields.isCompleted) as? Bool ?? false
        )
    }

    /// The position preserves the list's manual order, which the model
    /// itself only carries implicitly as its array index.
    func firestoreData(position: Int) -> [String: Any] {
        [
            ToDoFirestoreSchema.Field.title: title,
            ToDoFirestoreSchema.Field.notes: notes,
            ToDoFirestoreSchema.Field.isCompleted: isCompleted,
            ToDoFirestoreSchema.Field.position: position,
            ToDoFirestoreSchema.Field.lastUpdate: Timestamp(date: Date())
        ]
    }
}

final class ToDoFirestoreService: @unchecked Sendable {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    /// Uploads every item, overwriting documents with the same id so the
    /// backup always reflects the current local state.
    func backUp(_ items: [ItemModel]) async throws {
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

    /// Overwrites the collection to exactly match the given items, deleting
    /// documents for items that no longer exist locally. Used by the live
    /// "Store Data in Firebase" mode so local deletions propagate.
    func replaceAll(_ items: [ItemModel]) async throws {
        let collection = firestore.collection(ToDoFirestoreSchema.collection)
        let existingIDs = try await collection.getDocuments().documents.map(\.documentID)
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

    /// Fetches items in their backed-up list order.
    func fetchAll() async throws -> [ItemModel] {
        let snapshot = try await firestore.collection(ToDoFirestoreSchema.collection)
            .order(by: ToDoFirestoreSchema.Field.position)
            .getDocuments()
        return snapshot.documents.map(ItemModel.init)
    }
}
