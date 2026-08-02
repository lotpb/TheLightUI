//
//  CustomerStore.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class CustomerStore {
    var items = [CustomerItem]()
    var isLoading = false
    var errorMessage = ""

    @ObservationIgnored private let customerService: CustomerServicing
    // nonisolated(unsafe): accessed in nonisolated deinit; only written on @MainActor otherwise.
    @ObservationIgnored private nonisolated(unsafe) var listener: CustomerListener?

    init(customerService: CustomerServicing = FirebaseCustomerService()) {
        self.customerService = customerService
        fetchData()
    }

    func fetchData(showsLoadingIndicator: Bool = true) {
        if showsLoadingIndicator {
            isLoading = true
        }
        listener?.remove()
        listener = customerService.listenForCustomers { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

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
    }

    func deleteItems(_ itemsToDelete: [CustomerItem]) {
        Task {
            for item in itemsToDelete {
                do {
                    try await customerService.deleteCustomer(id: item.id)
                    // No optimistic removal: the live Firestore listener updates
                    // `items` once the delete is confirmed, which is the correct
                    // source of truth. Optimistic removal races the listener and
                    // can restore a deleted item if the snapshot arrives first.
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
