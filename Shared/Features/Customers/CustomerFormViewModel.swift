//
//  CustomerFormViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class CustomerFormViewModel {
    // The customer record being created or edited. The form binds directly
    // to these fields; there is no intermediate copy of the editable state.
    var detail: CustomerItem
    var showAlertUpdate = false
    // Dates are seeded from init parameters (callers may pass dates that
    // differ from `detail`), so they live here rather than on `detail`.
    var pickDate: Date
    var pickStartDate: Date
    var pickCompleteDate: Date
    var errorMessage = ""
    let mode: CustomerFormMode
    private(set) var shouldFocusFirstName = false

    @ObservationIgnored private let formService: CustomerFormServicing
    // nonisolated(unsafe): accessed in nonisolated deinit; only written on @MainActor otherwise.
    @ObservationIgnored private nonisolated(unsafe) var saveTask: Task<Void, Never>?

    // True while a Firestore save or update is in flight. Drives isButtonDisabled
    // to prevent a second tap from launching a concurrent write.
    private var isSaving = false

    var isButtonDisabled: Bool {
        detail.first.isEmpty || isSaving
    }

    var activeLabel: String {
        detail.isActive ? "Active:" : "Not Active:"
    }

    init(
        detail: CustomerItem,
        createDate: Date,
        startDate: Date,
        completeDate: Date,
        mode: CustomerFormMode,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        self.detail = detail
        self.pickDate = createDate
        self.pickStartDate = startDate
        self.pickCompleteDate = completeDate
        self.mode = mode
        self.formService = formService
    }

    deinit {
        saveTask?.cancel()
    }

    func loadFormState() {
        if mode.isNew {
            // Callers pre-select the category for new entries (e.g. the Leads
            // route passes "Lead"), so restore it after the blank-form reset.
            let presetCategory = detail.category
            detail.resetEditableFields()
            detail.category = presetCategory
            detail.isActive = true
            pickDate = Date()
            shouldFocusFirstName = true
        } else {
            pickDate = detail.creationDate
            pickStartDate = detail.startDate
            pickCompleteDate = detail.completionDate
        }
    }

    func consumeFirstNameFocusRequest() {
        shouldFocusFirstName = false
    }

    func incrementAmount() {
        detail.amount += 1000
    }

    func decrementAmount() {
        detail.amount = max(0, detail.amount - 1000)
    }

    func incrementQuantity() {
        detail.quantity += 1
    }

    func decrementQuantity() {
        detail.quantity = max(0, detail.quantity - 1)
    }

    func saveButtonTapped() {
        if mode.isNew {
            saveData()
        } else {
            updateData()
        }
    }

    private func saveData() {
        guard let uid = formService.currentUserId else {
            errorMessage = "Sign in before saving a new customer."
            return
        }
        let payload = makePayload(userId: uid)
        performSave {
            let documentID = try await self.formService.addCustomer(payload)
            guard !Task.isCancelled else { return }
            self.detail.resetEditableFields()
            self.showAlertUpdate = true
            self.errorMessage = ""
            print("Document added with ID: \(documentID)")
        }
    }

    private func updateData() {
        guard !detail.id.isEmpty else {
            errorMessage = "Cannot update a customer without a document ID."
            return
        }
        let payload = makePayload()
        performSave {
            try await self.formService.updateCustomer(id: self.detail.id, payload: payload)
            guard !Task.isCancelled else { return }
            self.detail.resetEditableFields()
            self.showAlertUpdate = true
            self.errorMessage = ""
        }
    }

    private func performSave(_ work: @escaping () async throws -> Void) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            isSaving = true
            defer { isSaving = false }
            do {
                try await work()
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func makePayload(userId: String? = nil) -> CustomerFormPayload {
        CustomerFormPayload(
            customer: detail,
            amount: detail.amount,
            quantity: detail.quantity,
            rate: detail.rate,
            creationDate: pickDate,
            startDate: pickStartDate,
            completionDate: pickCompleteDate,
            userId: userId
        )
    }
}
