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
    func listenForCustomers(onChange: @escaping @Sendable (Result<[CustomerItem], Error>) -> Void) -> CustomerListener
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

    func listenForCustomers(onChange: @escaping @Sendable (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
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

// MARK: - Local JSON

private struct NoOpCustomerListener: CustomerListener {
    func remove() {}
}

/// Reads and writes customers from Documents/Customerswift.json.
/// Used when "Store Data on Device" is enabled in Settings.
final class LocalJSONCustomerService: CustomerServicing, Sendable {
    static let fileName = "Customerswift.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func listenForCustomers(onChange: @escaping @Sendable (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        Task {
            do {
                let data = try Data(contentsOf: Self.fileURL)
                let records = try CustomerJSONTransfer.decodeRecords(from: data)
                onChange(.success(records.map(\.customerItem)))
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError {
                    onChange(.success([]))
                } else {
                    onChange(.failure(error))
                }
            }
        }
        return NoOpCustomerListener()
    }

    func deleteCustomer(id: String) async throws {
        let url = Self.fileURL
        guard let data = try? Data(contentsOf: url) else { return }
        var records = try CustomerJSONTransfer.decodeRecords(from: data)
        records.removeAll { $0.id == id }
        let updated = try CustomerJSONTransfer.exportData(for: records.map(\.customerItem))
        try updated.write(to: url, options: .atomic)
    }
}
