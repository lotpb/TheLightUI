//
//  CustomerData.swift
//  TheLightUI
//

import Foundation

@MainActor
final class CustomerData: ObservableObject {
    @Published var items = [CustomerItem]()
    @Published var isLoading = false
    @Published var errorMessage = ""

    private let customerService: CustomerServicing
    private var listener: CustomerListener?

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
                    items.removeAll { $0.id == item.id }
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
