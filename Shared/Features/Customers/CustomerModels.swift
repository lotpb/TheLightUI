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
struct CustomerItem: Identifiable, Equatable, Hashable {
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
    var callback: String = ""
    var adNo: String = ""

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

    // Known values of the Firestore "category" field, shared by the main-menu
    // routes, the list filter, the form picker, and the legacy-lead import so
    // the literals live in one place. Raw values match the stored field.
    enum Category: String, CaseIterable {
        case lead = "Lead"
        case customer = "Customer"
        case vendor = "Vendor"
        case employee = "Employee"

        // Navigation title for the matching main-menu route.
        var listTitle: String {
            switch self {
            case .lead: return "Leads"
            case .customer: return "Customers"
            case .vendor: return "Vendors"
            case .employee: return "Employee"
            }
        }

        // Stored values vary in casing, so match case-insensitively.
        func matches(_ storedValue: String) -> Bool {
            storedValue.caseInsensitiveCompare(rawValue) == .orderedSame
        }
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
        callback = ""
        adNo = ""
    }
}
// MARK: - Picker Data
@Observable
class PickerDataModel {
    var pickSalesman = ["", "Peter Balsamo", "Adam Monteleone", "John Pellegrino", "Mike Agunzo"]
    var pickJob = ["", "Windows", "Siding", "Doors", "Roofing"]
    // Vendor profession picker — static so the data layer can look up an index without a view model instance.
    static let defaultPickProfession = ["", "Auto"]
    var pickProfession = PickerDataModel.defaultPickProfession
    var pickProduct = ["", "Alside", "Andersen", "Ideal", "Marvin"]
    var pickContractor = ["", "A & S Home Improvement", "Islandwide Gutters", "Ashland Home Improvement", "John Kat Windows", "Jose Rosa", "Peter Balsamo"]
    var pickRate = ["5", "4", "3", "2", "1"]
    var pickAdvertiser = ["", "Reco", "Web"]
    var pickCallback = ["", "Yes"]
    // Values match the main-menu route filters (Leads/Customers/Vendors/Employee).
    var pickCategory = [""] + CustomerItem.Category.allCases.map(\.rawValue)
}
