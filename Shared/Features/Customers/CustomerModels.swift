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
    var companyName: String = ""
    var leadSource: String = ""
    var paymentStatus: String = ""
    var paymentTerms: String = ""
    var leadStatus: String = ""
    var lastContactDate: String = ""
    var contactAttempts: Int = 0
    var taxId: String = ""
    var accountNumber: String = ""
    var payType: String = ""
    var commissionRate: String = ""
    var userRole: String = ""
    var lastLogin: String = ""

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
        companyName = ""
        leadSource = ""
        paymentStatus = ""
        paymentTerms = ""
        leadStatus = ""
        lastContactDate = ""
        contactAttempts = 0
        taxId = ""
        accountNumber = ""
        payType = ""
        commissionRate = ""
        userRole = ""
        lastLogin = ""
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

    @ObservationIgnored private var fetchTask: Task<Void, Never>?

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
        updatePickerField("salesman", arrayUnion: [name])
    }

    func deleteSalesman(at offsets: IndexSet) {
        let removed = offsets.map { pickSalesman[$0] }
        pickSalesman.remove(atOffsets: offsets)
        persist(pickSalesman, key: Self.salesmanKey)
        updatePickerField("salesman", arrayRemove: removed)
    }

    // MARK: Job
    func addJob(_ name: String) {
        pickJob.append(name)
        persist(pickJob, key: Self.jobKey)
        updatePickerField("job", arrayUnion: [name])
    }

    func deleteJob(at offsets: IndexSet) {
        let removed = offsets.map { pickJob[$0] }
        pickJob.remove(atOffsets: offsets)
        persist(pickJob, key: Self.jobKey)
        updatePickerField("job", arrayRemove: removed)
    }

    // MARK: Product
    func addProduct(_ name: String) {
        pickProduct.append(name)
        persist(pickProduct, key: Self.productKey)
        updatePickerField("product", arrayUnion: [name])
    }

    func deleteProduct(at offsets: IndexSet) {
        let removed = offsets.map { pickProduct[$0] }
        pickProduct.remove(atOffsets: offsets)
        persist(pickProduct, key: Self.productKey)
        updatePickerField("product", arrayRemove: removed)
    }

    // MARK: Advertiser
    func addAdvertiser(_ name: String) {
        pickAdvertiser.append(name)
        persist(pickAdvertiser, key: Self.advertiserKey)
        updatePickerField("advertiser", arrayUnion: [name])
    }

    func deleteAdvertiser(at offsets: IndexSet) {
        let removed = offsets.map { pickAdvertiser[$0] }
        pickAdvertiser.remove(atOffsets: offsets)
        persist(pickAdvertiser, key: Self.advertiserKey)
        updatePickerField("advertiser", arrayRemove: removed)
    }

    // MARK: Contractor
    func addContractor(_ name: String) {
        pickContractor.append(name)
        persist(pickContractor, key: Self.contractorKey)
        updatePickerField("contractor", arrayUnion: [name])
    }

    func deleteContractor(at offsets: IndexSet) {
        let removed = offsets.map { pickContractor[$0] }
        pickContractor.remove(atOffsets: offsets)
        persist(pickContractor, key: Self.contractorKey)
        updatePickerField("contractor", arrayRemove: removed)
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
        fetchTask?.cancel()
        let ref = Firestore.firestore().collection(Self.fsCollection).document(Self.fsDocument)
        fetchTask = Task { [weak self] in
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

    deinit {
        fetchTask?.cancel()
    }

    // Atomically adds values to a single Firestore array field.
    // setData(merge:true) creates the document if absent, so this is safe
    // for first-time writes and concurrent calls from multiple devices.
    private func updatePickerField(_ field: String, arrayUnion values: [String]) {
        guard !values.isEmpty else { return }
        let ref = Firestore.firestore().collection(Self.fsCollection).document(Self.fsDocument)
        Task { try? await ref.setData([field: FieldValue.arrayUnion(values)], merge: true) }
    }

    // Atomically removes values from a single Firestore array field.
    private func updatePickerField(_ field: String, arrayRemove values: [String]) {
        guard !values.isEmpty else { return }
        let ref = Firestore.firestore().collection(Self.fsCollection).document(Self.fsDocument)
        Task { try? await ref.setData([field: FieldValue.arrayRemove(values)], merge: true) }
    }
}
