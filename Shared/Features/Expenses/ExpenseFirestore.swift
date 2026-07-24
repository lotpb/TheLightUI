//
//  ExpenseFirestore.swift
//  TheLightUI
//

// Firestore schema constants, record mapping, and the backup/restore
// service for the Expenses collection.

import Foundation
import FirebaseFirestore

enum ExpenseFirestoreSchema {
    static let collection = "Expenses"

    enum Field {
        static let title = "title"
        static let amount = "amount"
        static let category = "category"
        static let date = "date"
        static let notes = "notes"
        static let isReimbursable = "isReimbursable"
        static let lastUpdate = "lastUpdate"
    }
}

extension ExpenseRecord {
    /// Maps a Firestore document back to a record. Documents are keyed by
    /// the expense UUID, so an unparseable ID means the document was not
    /// written by this app and is skipped.
    init?(document: QueryDocumentSnapshot) {
        guard let id = UUID(uuidString: document.documentID) else { return nil }
        let fields = ExpenseFirestoreSchema.Field.self

        self.id = id
        self.title = document.get(fields.title) as? String ?? ""
        self.amount = (document.get(fields.amount) as? NSNumber)?.doubleValue ?? 0
        self.category = ExpenseCategory(rawValue: document.get(fields.category) as? String ?? "") ?? .other
        self.date = (document.get(fields.date) as? Timestamp)?.dateValue() ?? Date()
        self.notes = document.get(fields.notes) as? String ?? ""
        self.isReimbursable = document.get(fields.isReimbursable) as? Bool ?? false
        self.lastUpdate = (document.get(fields.lastUpdate) as? Timestamp)?.dateValue()
    }

    var firestoreData: [String: Any] {
        [
            ExpenseFirestoreSchema.Field.title: title,
            ExpenseFirestoreSchema.Field.amount: amount,
            ExpenseFirestoreSchema.Field.category: category.rawValue,
            ExpenseFirestoreSchema.Field.date: Timestamp(date: date),
            ExpenseFirestoreSchema.Field.notes: notes,
            ExpenseFirestoreSchema.Field.isReimbursable: isReimbursable,
            // The edit time, not the upload time, so conflict resolution
            // compares when the expense actually changed.
            ExpenseFirestoreSchema.Field.lastUpdate: Timestamp(date: lastUpdate ?? Date())
        ]
    }
}

actor ExpenseFirestoreService {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    /// Uploads every record, overwriting documents with the same id so the
    /// backup always reflects the current local state.
    func backUp(_ records: [ExpenseRecord]) async throws {
        let collection = firestore.collection(ExpenseFirestoreSchema.collection)

        // Firestore caps a write batch at 500 operations.
        for start in stride(from: 0, to: records.count, by: 500) {
            let batch = firestore.batch()
            for record in records[start..<min(start + 500, records.count)] {
                batch.setData(record.firestoreData, forDocument: collection.document(record.id.uuidString))
            }
            try await batch.commit()
        }
    }

    func delete(id: UUID) async throws {
        try await firestore.collection(ExpenseFirestoreSchema.collection)
            .document(id.uuidString)
            .delete()
    }

    func fetchAll() async throws -> [ExpenseRecord] {
        let snapshot = try await firestore.collection(ExpenseFirestoreSchema.collection).getDocuments()
        return snapshot.documents.compactMap(ExpenseRecord.init)
    }
}
