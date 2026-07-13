//
//  CustomerModels.swift
//  TheLightUI
//

import Foundation
import Observation

// MARK: - Customer Form Mode
enum CustomerFormMode: String, Equatable {
    case new = "New"
    case edit = "Edit"

    var isNew: Bool {
        self == .new
    }
}

// MARK: - Customer Model
struct CustomerItem: Identifiable, Equatable {
    var id: String
    var isActive: Bool
    var first: String
    var lastname: String
    var street: String
    var city: String
    var state: String
    var zip: String
    var amount: Int
    var creationDate: Date
    var rate: String
    var phone: String
    var comments: String
    var spouse: String
    var email: String
    var contractorIndex: Int
    var photo: String
    var lastUpdateDate: Date
    var startDate: Date
    var completionDate: Date
    var quantity: Int
    var salesIndex: Int
    var jobIndex: Int
    var productIndex: Int
    // Legacy Firestore category value (e.g. "Customer"); defaulted so call
    // sites and JSON imports without the field keep working.
    var category: String = ""

    static var emptyCustomer: CustomerItem {
        CustomerItem(
            id: "",
            isActive: true,
            first: "",
            lastname: "",
            street: "",
            city: "",
            state: "",
            zip: "",
            amount: 0,
            creationDate: Date(),
            rate: "",
            phone: "",
            comments: "",
            spouse: "",
            email: "",
            contractorIndex: 0,
            photo: "",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 0,
            salesIndex: 0,
            jobIndex: 0,
            productIndex: 0
        )
    }

    mutating func resetEditableFields() {
        first = ""
        lastname = ""
        street = ""
        city = ""
        state = ""
        zip = ""
        amount = 0
        rate = ""
        phone = ""
        comments = ""
        spouse = ""
        email = ""
        contractorIndex = 0
        photo = ""
        quantity = 0
        salesIndex = 0
        jobIndex = 0
        productIndex = 0
        category = ""
    }
}
// MARK: - Picker Data
@Observable
class PickerDataModel {
    var pickSalesman = ["", "Peter Balsamo", "Adam Monteleone", "John Pellegrino", "Mike Agunzo"]
    var pickJob = ["", "Windows", "Siding", "Doors", "Roofing"]
    var pickProduct = ["", "Alside", "Andersen", "Ideal", "Marvin"]
    var pickContractor = ["", "A & S Home Improvement", "Islandwide Gutters", "Ashland Home Improvement", "John Kat Windows", "Jose Rosa", "Peter Balsamo"]
    var pickRate = ["5", "4", "3", "2", "1"]
    // Values match the main-menu route filters (Leads/Customers/Vendors/Employee).
    var pickCategory = ["", "Lead", "Customer", "Vendor", "Employee"]
}
