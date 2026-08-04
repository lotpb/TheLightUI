//
//  CustomerModels.swift
//  TheLightUI
//

import Foundation
import Observation
import FirebaseFirestore

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
    var contractor: String
    var photo: String
    var lastUpdateDate: Date
    var startDate: Date
    var completionDate: Date
    var quantity: Int
    var salesman: String
    var job: String
    var product: String
    // Legacy Firestore category value (e.g. "Customer"); defaulted so call
    // sites and JSON imports without the field keep working.
    var category: String = ""
    var callback: String = ""
    var adNo: String = ""
    var birthDate: String = ""
    var driverLicense: String = ""

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
            contractor: "",
            photo: "",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 0,
            salesman: "",
            job: "",
            product: ""
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
        contractor = ""
        photo = ""
        quantity = 0
        salesman = ""
        job = ""
        product = ""
        category = ""
        callback = ""
        adNo = ""
        birthDate = ""
        driverLicense = ""
    }
}

// MARK: - Picker Data
@MainActor @Observable
class PickerDataModel {
    // UserDefaults keys — used as a local cache so the app works offline.
    private static let salesmanKey    = "picker.salesman"
    private static let jobKey         = "picker.job"
    private static let productKey     = "picker.product"
    private static let advertiserKey  = "picker.advertiser"
    private static let contractorKey  = "picker.contractor"

    private static let defaultSalesman: [String]    = [""]
    private static let defaultJob: [String]         = [""]
    private static let defaultProduct: [String]     = [""]
    private static let defaultAdvertiser: [String]  = [""]
    private static let defaultContractor: [String]  = [""]

    // Firestore path: settings/pickerLists
    private static let fsCollection = "settings"
    private static let fsDocument   = "pickerLists"

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
        // Start with local cache so UI is ready immediately.
        pickSalesman   = Self.load(key: Self.salesmanKey,   default: Self.defaultSalesman)
        pickJob        = Self.load(key: Self.jobKey,        default: Self.defaultJob)
        pickProduct    = Self.load(key: Self.productKey,    default: Self.defaultProduct)
        pickAdvertiser = Self.load(key: Self.advertiserKey, default: Self.defaultAdvertiser)
        pickContractor = Self.load(key: Self.contractorKey, default: Self.defaultContractor)
        fetchFromFirestore()
    }

    // MARK: Salesman
    func addSalesman(_ name: String) {
        pickSalesman.append(name)
        persist(pickSalesman, key: Self.salesmanKey)
        saveToFirestore()
    }

    func deleteSalesman(at offsets: IndexSet) {
        pickSalesman.remove(atOffsets: offsets)
        persist(pickSalesman, key: Self.salesmanKey)
        saveToFirestore()
    }

    // MARK: Job
    func addJob(_ name: String) {
        pickJob.append(name)
        persist(pickJob, key: Self.jobKey)
        saveToFirestore()
    }

    func deleteJob(at offsets: IndexSet) {
        pickJob.remove(atOffsets: offsets)
        persist(pickJob, key: Self.jobKey)
        saveToFirestore()
    }

    // MARK: Product
    func addProduct(_ name: String) {
        pickProduct.append(name)
        persist(pickProduct, key: Self.productKey)
        saveToFirestore()
    }

    func deleteProduct(at offsets: IndexSet) {
        pickProduct.remove(atOffsets: offsets)
        persist(pickProduct, key: Self.productKey)
        saveToFirestore()
    }

    // MARK: Advertiser
    func addAdvertiser(_ name: String) {
        pickAdvertiser.append(name)
        persist(pickAdvertiser, key: Self.advertiserKey)
        saveToFirestore()
    }

    func deleteAdvertiser(at offsets: IndexSet) {
        pickAdvertiser.remove(atOffsets: offsets)
        persist(pickAdvertiser, key: Self.advertiserKey)
        saveToFirestore()
    }

    // MARK: Contractor
    func addContractor(_ name: String) {
        pickContractor.append(name)
        persist(pickContractor, key: Self.contractorKey)
        saveToFirestore()
    }

    func deleteContractor(at offsets: IndexSet) {
        pickContractor.remove(atOffsets: offsets)
        persist(pickContractor, key: Self.contractorKey)
        saveToFirestore()
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

    // Fetches the picker lists from Firestore and overwrites local state.
    // Silently falls back to the UserDefaults cache if the fetch fails.
    private func fetchFromFirestore() {
        let ref = Firestore.firestore().collection(Self.fsCollection).document(Self.fsDocument)
        Task { [weak self] in
            guard let self else { return }
            guard let doc = try? await ref.getDocument(), doc.exists else { return }
            if let v = doc.get("salesman") as? [String], !v.isEmpty {
                self.pickSalesman = v; self.persist(v, key: Self.salesmanKey)
            }
            if let v = doc.get("job") as? [String], !v.isEmpty {
                self.pickJob = v; self.persist(v, key: Self.jobKey)
            }
            if let v = doc.get("product") as? [String], !v.isEmpty {
                self.pickProduct = v; self.persist(v, key: Self.productKey)
            }
            if let v = doc.get("advertiser") as? [String], !v.isEmpty {
                self.pickAdvertiser = v; self.persist(v, key: Self.advertiserKey)
            }
            if let v = doc.get("contractor") as? [String], !v.isEmpty {
                self.pickContractor = v; self.persist(v, key: Self.contractorKey)
            }
        }
    }

    // Writes all five picker lists to Firestore. Called after every add/delete.
    private func saveToFirestore() {
        let ref = Firestore.firestore().collection(Self.fsCollection).document(Self.fsDocument)
        let data: [String: Any] = [
            "salesman":   pickSalesman,
            "job":        pickJob,
            "product":    pickProduct,
            "advertiser": pickAdvertiser,
            "contractor": pickContractor
        ]
        Task {
            try? await ref.setData(data)
        }
    }
}
