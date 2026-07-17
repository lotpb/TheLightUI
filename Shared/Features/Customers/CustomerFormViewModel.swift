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
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    var isButtonDisabled: Bool {
        detail.first.isEmpty
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

        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            do {
                let documentID = try await formService.addCustomer(payload)
                guard !Task.isCancelled else { return }
                detail.resetEditableFields()
                showAlertUpdate = true
                errorMessage = ""
                print("Document added with ID: \(documentID)")
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
                print("Error adding document: \(error)")
            }
        }
    }

    private func updateData() {
        guard !detail.id.isEmpty else {
            errorMessage = "Cannot update a customer without a document ID."
            return
        }

        let payload = makePayload()

        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await formService.updateCustomer(id: detail.id, payload: payload)
                guard !Task.isCancelled else { return }
                detail.resetEditableFields()
                showAlertUpdate = true
                errorMessage = ""
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
                print(error.localizedDescription)
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
