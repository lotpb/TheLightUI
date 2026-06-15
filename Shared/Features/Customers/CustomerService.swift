//
//  CustomerService.swift
//  TheLightUI
//

import Foundation
import FirebaseFirestore

protocol CustomerListener {
    func remove()
}

protocol CustomerServicing {
    @discardableResult
    func listenForCustomers(onChange: @escaping (Result<[CustomerItem], Error>) -> Void) -> CustomerListener
    func deleteCustomer(id: String) async throws
}

final class FirebaseCustomerListener: CustomerListener {
    private let registration: ListenerRegistration

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration.remove()
    }
}

final class FirebaseCustomerService: CustomerServicing {
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

                let items = snapshot?.documents.map {
                    CustomerFirestoreDTO(document: $0).customerItem
                } ?? []
                onChange(.success(items))
            }

        return FirebaseCustomerListener(registration: registration)
    }

    func deleteCustomer(id: String) async throws {
        try await firestore.collection(CustomerFirestoreSchema.collection)
            .document(id)
            .deleteAsync()
    }
}
