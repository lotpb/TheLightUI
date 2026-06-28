//
//  CustomerFormViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class CustomerFormViewModel {
    var detail: CustomerItem
    var showAlertUpdate = false
    var activeIsOn = true
    var pickDate: Date
    var pickStartDate: Date
    var pickCompleteDate: Date
    var mode: CustomerFormMode
    var selectedRate = ""
    var selectContractor = 0
    var selectSalesman = 0
    var selectJob = 0
    var selectProduct = 0
    var amount = 0
    var quantity = 0
    var errorMessage = ""
    private(set) var shouldFocusFirstName = false

    @ObservationIgnored private let formService: CustomerFormServicing
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    var isButtonDisabled: Bool {
        detail.first.isEmpty
    }

    var activeLabel: String {
        activeIsOn ? "Active:" : "Not Active:"
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
        amount = detail.amount

        if mode.isNew {
            resetTextFields()
            pickDate = Date()
            detail.isActive = true
            activeIsOn = true
            shouldFocusFirstName = true
            return
        }

        selectSalesman = detail.salesIndex
        selectJob = detail.jobIndex
        selectProduct = detail.productIndex
        quantity = detail.quantity
        selectedRate = detail.rate
        selectContractor = detail.contractorIndex
        activeIsOn = detail.isActive
        pickDate = detail.creationDate
        pickStartDate = detail.startDate
        pickCompleteDate = detail.completionDate
    }

    func consumeFirstNameFocusRequest() {
        shouldFocusFirstName = false
    }

    func updateActiveStatus() {
        detail.isActive = activeIsOn
    }

    func updateSalesman(_ index: Int) {
        detail.salesIndex = index
    }

    func updateJob(_ index: Int) {
        detail.jobIndex = index
    }

    func updateProduct(_ index: Int) {
        detail.productIndex = index
    }

    func updateContractor(_ index: Int) {
        detail.contractorIndex = index
    }

    func incrementAmount() {
        amount += 1000
    }

    func decrementAmount() {
        amount = max(0, amount - 1000)
    }

    func incrementQuantity() {
        quantity += 1
    }

    func decrementQuantity() {
        quantity = max(0, quantity - 1)
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
                resetTextFields()
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
                resetTextFields()
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
            amount: amount,
            quantity: quantity,
            rate: selectedRate,
            creationDate: pickDate,
            startDate: pickStartDate,
            completionDate: pickCompleteDate,
            userId: userId
        )
    }

    private func resetTextFields() {
        detail.resetEditableFields()
        amount = 0
        quantity = 0
        selectedRate = ""
        selectContractor = 0
        selectSalesman = 0
        selectJob = 0
        selectProduct = 0
    }
}
