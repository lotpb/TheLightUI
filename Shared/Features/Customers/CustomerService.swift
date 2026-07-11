//
//  CustomerService.swift
//  TheLightUI
//

import Foundation
import FirebaseFirestore

protocol CustomerListener: Sendable {
    func remove()
}

protocol CustomerServicing: Sendable {
    @discardableResult
    func listenForCustomers(onChange: @escaping (Result<[CustomerItem], Error>) -> Void) -> CustomerListener
    func deleteCustomer(id: String) async throws
}

final class FirebaseCustomerListener: CustomerListener, @unchecked Sendable {
    private let registration: ListenerRegistration

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration.remove()
    }
}

final class FirebaseCustomerService: CustomerServicing, @unchecked Sendable {
    private let firestore: Firestore
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func listenForCustomers(onChange: @escaping (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        let registration = firestore.collection(CustomerFirestoreSchema.collection)
            .order(by: CustomerFirestoreSchema.Field.creationDate, descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                let items = snapshot?.documents.map(CustomerItem.init) ?? []
                onChange(.success(items))
            }

        return FirebaseCustomerListener(registration: registration)
    }

    func deleteCustomer(id: String) async throws {
        try await firestore.collection(CustomerFirestoreSchema.collection)
            .document(id)
            .delete()
    }
}
