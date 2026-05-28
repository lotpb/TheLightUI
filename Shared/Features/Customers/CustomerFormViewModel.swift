//
//  CustomerFormViewModel.swift
//  TheLightUI
//

import Foundation

@MainActor
final class CustomerFormViewModel: ObservableObject {
    @Published var detail: CustomerItem
    @Published var showAlertUpdate = false
    @Published var activeIsOn = true
    @Published var pickDate: Date
    @Published var pickStartDate: Date
    @Published var pickCompleteDate: Date
    @Published var status: String
    @Published var selectedRate = ""
    @Published var selectContractor = 0
    @Published var selectSalesman = 0
    @Published var selectJob = 0
    @Published var selectProduct = 0
    @Published var amount = 0
    @Published var quantity = 0
    @Published var errorMessage = ""
    @Published private(set) var shouldFocusFirstName = false

    private let formService: CustomerFormServicing

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
        status: String,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        self.detail = detail
        self.pickDate = createDate
        self.pickStartDate = startDate
        self.pickCompleteDate = completeDate
        self.status = status
        self.formService = formService
    }

    func loadFormState() {
        amount = detail.amount

        if status == "New" {
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
        amount -= 1000
    }

    func incrementQuantity() {
        quantity += 1
    }

    func decrementQuantity() {
        quantity -= 1
    }

    func saveButtonTapped() {
        if status == "New" {
            saveData()
        } else {
            updateData()
        }
    }

    private func saveData() {
        guard let uid = formService.currentUserId else { return }
        let payload = makePayload(userId: uid)

        Task {
            do {
                let documentID = try await formService.addCustomer(payload)
                resetTextFields()
                showAlertUpdate = true
                errorMessage = ""
                print("Document added with ID: \(documentID)")
            } catch {
                errorMessage = error.localizedDescription
                print("Error adding document: \(error)")
            }
        }
    }

    private func updateData() {
        let payload = makePayload()

        Task {
            do {
                try await formService.updateCustomer(id: detail.id, payload: payload)
                resetTextFields()
                showAlertUpdate = true
                errorMessage = ""
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
        detail.first = ""
        detail.lastname = ""
        detail.contractorIndex = 0
        detail.street = ""
        detail.city = ""
        detail.state = ""
        detail.zip = ""
        detail.phone = ""
        detail.amount = 0
        detail.email = ""
        detail.spouse = ""
        detail.photo = ""
        detail.comments = ""
        detail.quantity = 0
        detail.rate = ""
        detail.salesIndex = 0
        detail.jobIndex = 0
        detail.productIndex = 0
        amount = 0
        quantity = 0
        selectedRate = ""
        selectContractor = 0
        selectSalesman = 0
        selectJob = 0
        selectProduct = 0
    }
}
