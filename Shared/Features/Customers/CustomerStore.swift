//
//  CustomerStore.swift
//  TheLightUI
//

import Foundation
import Observation

// Thread-safe wrapper for a CustomerListener. `deinit` fires on an arbitrary
// thread while `@MainActor` methods run on the main thread; the NSLock
// serialises both without requiring `nonisolated(unsafe)`.
private final class ListenerBox: @unchecked Sendable {
    private let lock = NSLock()
    private var listener: (any CustomerListener)?

    func replace(with new: any CustomerListener) {
        lock.withLock {
            listener?.remove()
            listener = new
        }
    }

    func removeAll() {
        lock.withLock {
            listener?.remove()
            listener = nil
        }
    }
}

@MainActor
@Observable
final class CustomerStore {
    var items = [CustomerItem]()
    var isLoading = false
    var errorMessage = ""

    @ObservationIgnored private let customerService: CustomerServicing
    @ObservationIgnored private let listenerBox = ListenerBox()
    @ObservationIgnored private var listenerGeneration = 0

    init(customerService: CustomerServicing = FirebaseCustomerService()) {
        self.customerService = customerService
        fetchData()
    }

    func fetchData(showsLoadingIndicator: Bool = true) {
        if showsLoadingIndicator {
            isLoading = true
        }
        listenerGeneration += 1
        let generation = listenerGeneration

        let newListener = customerService.listenForCustomers { [weak self] result in
            Task { @MainActor in
                guard let self, self.listenerGeneration == generation else { return }

                switch result {
                case .success(let items):
                    self.items = items
                    self.errorMessage = ""
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }

                self.isLoading = false
            }
        }
        listenerBox.replace(with: newListener)
    }

    func deleteItems(_ itemsToDelete: [CustomerItem]) {
        Task {
            var failures = 0
            var lastError: Error?
            for item in itemsToDelete {
                do {
                    try await customerService.deleteCustomer(id: item.id)
                    // No optimistic removal: the live Firestore listener updates
                    // `items` once the delete is confirmed, which is the correct
                    // source of truth. Optimistic removal races the listener and
                    // can restore a deleted item if the snapshot arrives first.
                } catch {
                    failures += 1
                    lastError = error
                }
            }
            if let lastError {
                errorMessage = failures == 1
                    ? lastError.localizedDescription
                    : "\(failures) items could not be deleted."
            }
        }
    }

    deinit {
        listenerBox.removeAll()
    }
}
