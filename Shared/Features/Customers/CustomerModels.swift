//
//  CustomerModels.swift
//  TheLightUI
//

import Foundation

// MARK: - Configuration
enum CustomerConfiguration {
    static let leadNews = "Company to expand to a new web advertising directive this week."
    static let customerNews = "Check our new line of fabulous windows and siding."
    static let vendorNews = "Peter Balsamo Appointed to United's Board of Directors."
    static let employeeNews = "Health benifits cancelled immediately, starting today."
    static let baseURL = "http://lotpb.github.io/UnitedWebPage/index.html"
}

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
    var status: CustomerFormMode
    var formController: String

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
            productIndex: 0,
            status: .new,
            formController: "Customer"
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
    }
}
// MARK: - Picker Data
class PickerDataModel: ObservableObject {
    @Published var pickSalesman = [String]()
    @Published var pickJob = [String]()
    @Published var pickProduct = [String]()
    @Published var pickContractor = [String]()
    @Published var pickRate = [String]()

    init() {
        getData()
    }

    func getData() {
        pickSalesman.append(contentsOf: [
            "", "Peter Balsamo", "Adam Monteleone", "John Pellegrino", "Mike Agunzo"
        ])
        pickJob.append(contentsOf: [
            "", "Windows", "Siding", "Doors", "Roofing"
        ])
        pickProduct.append(contentsOf: [
            "", "Alside", "Andersen", "Ideal", "Marvin"
        ])
        pickContractor.append(contentsOf: [
            "", "A & S Home Improvement", "Islandwide Gutters", "Ashland Home Improvement", "John Kat Windows", "Jose Rosa", "Peter Balsamo"
        ])
        pickRate.append(contentsOf: ["5", "4", "3", "2", "1"])
    }
}
