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
            .addDocumentAsync(
                data: payload.firestoreData,
                missingDocumentIdError: CustomerFormServiceError.missingDocumentId
            )
    }

    func updateCustomer(id: String, payload: CustomerFormPayload) async throws {
        try await manager.firestore
            .collection(CustomerFirestoreSchema.collection)
            .document(id)
            .setDataAsync(payload.firestoreData)
    }
}

enum CustomerFormServiceError: LocalizedError {
    case missingDocumentId

    var errorDescription: String? {
        switch self {
        case .missingDocumentId:
            return "Could not read the new customer document ID."
        }
    }
}
