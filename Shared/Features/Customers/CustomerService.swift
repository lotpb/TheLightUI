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
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    onChange(.failure(error))
                    return
                }

                let items = snapshot?.documents.map { self.makeCustomerItem(from: $0) } ?? []
                onChange(.success(items))
            }

        return FirebaseCustomerListener(registration: registration)
    }

    func deleteCustomer(id: String) async throws {
        try await firestore.collection(CustomerFirestoreSchema.collection)
            .document(id)
            .deleteAsync()
    }

    private func makeCustomerItem(from document: QueryDocumentSnapshot) -> CustomerItem {
        let fields = CustomerFirestoreSchema.Field.self
        let creationStamp = document.get(fields.creationDate) as? Timestamp
        let startStamp = document.get(fields.start) as? Timestamp
        let completeStamp = document.get(fields.completion) as? Timestamp
        let lastStamp = document.get(fields.lastUpdate) as? Timestamp
        let city = document.get(fields.city) as? String ?? ""
        let state = document.get(fields.state) as? String ?? ""
        let zip = document.get(fields.zip) as? String ?? ""
        let amount = (document.get(fields.amount) as? NSNumber)?.intValue ?? 0
        let quantity = (document.get(fields.quantity) as? NSNumber)?.intValue ?? 0
        let salesNo = (document.get(fields.salesNo) as? NSNumber)?.intValue ?? 0
        let jobNo = (document.get(fields.jobNo) as? NSNumber)?.intValue ?? 0
        let prodNo = (document.get(fields.prodNo) as? NSNumber)?.intValue ?? 0
        let contractor = Int(document.get(fields.contractor) as? String ?? "") ?? 0
        let active = document.get(fields.active) as? String ?? ""

        return CustomerItem(
            id: document.documentID,
            isActive: active == "1",
            first: document.get(fields.first) as? String ?? "",
            lastname: document.get(fields.lastname) as? String ?? "",
            street: document.get(fields.street) as? String ?? "",
            city: city,
            state: state,
            zip: zip,
            amount: amount,
            creationDate: creationStamp?.dateValue() ?? Date(),
            rate: document.get(fields.rate) as? String ?? "",
            phone: document.get(fields.phone) as? String ?? "",
            comments: document.get(fields.comments) as? String ?? "",
            spouse: document.get(fields.spouse) as? String ?? "",
            email: document.get(fields.email) as? String ?? "",
            contractorIndex: contractor,
            photo: document.get(fields.photo) as? String ?? "",
            lastUpdateDate: lastStamp?.dateValue() ?? Date(),
            startDate: startStamp?.dateValue() ?? Date(),
            completionDate: completeStamp?.dateValue() ?? Date(),
            quantity: quantity,
            salesIndex: salesNo,
            jobIndex: jobNo,
            productIndex: prodNo,
            status: "Edit",
            formController: "Customer"
        )
    }
}
