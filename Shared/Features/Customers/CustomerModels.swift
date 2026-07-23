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
    // UserDefaults keys for the five editable picker lists.
    private static let salesmanKey    = "picker.salesman"
    private static let jobKey         = "picker.job"
    private static let productKey     = "picker.product"
    private static let advertiserKey  = "picker.advertiser"
    private static let contractorKey  = "picker.contractor"

    private static let defaultSalesman: [String]    = ["", "Peter Balsamo"]
    private static let defaultJob: [String]          = ["", "Windows"]
    private static let defaultProduct: [String]      = ["", "Alside"]
    private static let defaultAdvertiser: [String]   = ["", "Reco"]
    private static let defaultContractor: [String]   = ["", "A & S Home Improvement"]

    var pickSalesman: [String]
    var pickJob: [String]
    var pickProduct: [String]
    var pickAdvertiser: [String]
    var pickContractor: [String]

    // Vendor profession picker — static so the data layer can look up an index without a view model instance.
    static let defaultPickProfession = ["", "Auto"]
    var pickProfession  = PickerDataModel.defaultPickProfession
    var pickRate        = ["5", "4", "3", "2", "1"]
    var pickCallback    = ["", "Yes"]
    // Values match the main-menu route filters (Leads/Customers/Vendors/Employee).
    var pickCategory    = [""] + CustomerItem.Category.allCases.map(\.rawValue)

    init() {
        pickSalesman   = Self.load(key: Self.salesmanKey,   default: Self.defaultSalesman)
        pickJob        = Self.load(key: Self.jobKey,        default: Self.defaultJob)
        pickProduct    = Self.load(key: Self.productKey,    default: Self.defaultProduct)
        pickAdvertiser = Self.load(key: Self.advertiserKey, default: Self.defaultAdvertiser)
        pickContractor = Self.load(key: Self.contractorKey, default: Self.defaultContractor)
    }

    // MARK: Salesman
    func addSalesman(_ name: String) {
        pickSalesman.append(name)
        persist(pickSalesman, key: Self.salesmanKey)
    }

    func deleteSalesman(at offsets: IndexSet) {
        pickSalesman.remove(atOffsets: offsets)
        persist(pickSalesman, key: Self.salesmanKey)
    }

    // MARK: Job
    func addJob(_ name: String) {
        pickJob.append(name)
        persist(pickJob, key: Self.jobKey)
    }

    func deleteJob(at offsets: IndexSet) {
        pickJob.remove(atOffsets: offsets)
        persist(pickJob, key: Self.jobKey)
    }

    // MARK: Product
    func addProduct(_ name: String) {
        pickProduct.append(name)
        persist(pickProduct, key: Self.productKey)
    }

    func deleteProduct(at offsets: IndexSet) {
        pickProduct.remove(atOffsets: offsets)
        persist(pickProduct, key: Self.productKey)
    }

    // MARK: Advertiser
    func addAdvertiser(_ name: String) {
        pickAdvertiser.append(name)
        persist(pickAdvertiser, key: Self.advertiserKey)
    }

    func deleteAdvertiser(at offsets: IndexSet) {
        pickAdvertiser.remove(atOffsets: offsets)
        persist(pickAdvertiser, key: Self.advertiserKey)
    }

    // MARK: Contractor
    func addContractor(_ name: String) {
        pickContractor.append(name)
        persist(pickContractor, key: Self.contractorKey)
    }

    func deleteContractor(at offsets: IndexSet) {
        pickContractor.remove(atOffsets: offsets)
        persist(pickContractor, key: Self.contractorKey)
    }

    // MARK: Private helpers
    private static func load(key: String, default defaultValue: [String]) -> [String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([String].self, from: data)
        else { return defaultValue }
        return saved
    }

    private func persist(_ items: [String], key: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
