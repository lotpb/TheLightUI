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

// `@unchecked Sendable`: wraps Firebase's ListenerRegistration, which is
// thread-safe by contract but lacks Sendable conformance in the SDK.
final class FirebaseCustomerListener: CustomerListener, @unchecked Sendable {
    private let registration: ListenerRegistration

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration.remove()
    }
}

// `@unchecked Sendable`: holds a Firestore reference, which is thread-safe
// by Firebase contract but lacks Sendable conformance in the SDK.
final class FirebaseCustomerService: CustomerServicing, @unchecked Sendable {
    private let firestore: Firestore
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func listenForCustomers(onChange: @escaping @Sendable (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        guard let companyId = CompanySession.companyId, !companyId.isEmpty else {
            onChange(.success([]))
            return NoOpCustomerListener()
        }

        let registration = firestore.collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.companyId, isEqualTo: companyId)
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

struct NoOpCustomerListener: CustomerListener {
    func remove() {}
}

/// Reads and writes customers from Documents/CustomerBackup.json.
/// Used when "Store Data on Device" is enabled in Settings.
final class LocalJSONCustomerService: CustomerServicing, Sendable {
    static let fileName = "CustomerBackup.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func listenForCustomers(onChange: @escaping @Sendable (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        Task.detached(priority: .userInitiated) {
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
