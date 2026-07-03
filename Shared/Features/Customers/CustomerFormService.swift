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
}

final class FirebaseCustomerFormService: CustomerFormServicing {
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
}
