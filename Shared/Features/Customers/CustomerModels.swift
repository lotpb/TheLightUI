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
    var status: String
    var formController: String

    var address: String {
        [city, state, zip].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var activeValue: String {
        isActive ? "1" : "0"
    }

    var formattedAmount: String {
        CustomerFormatters.currency.string(from: NSNumber(value: amount)) ?? "$0"
    }

    var formattedCreationDate: String {
        CustomerFormatters.mediumDate.string(from: creationDate)
    }

    var formattedLastUpdateDate: String {
        CustomerFormatters.mediumDate.string(from: lastUpdateDate)
    }

    var formattedStartDate: String {
        CustomerFormatters.mediumDate.string(from: startDate)
    }

    var formattedCompletionDate: String {
        CustomerFormatters.mediumDate.string(from: completionDate)
    }

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
            status: "New",
            formController: "Customer"
        )
    }
}
// MARK: - Customer Presentation
struct CustomerDetailField: Identifiable {
    let id = UUID().uuidString
    let name: String
    let label: String
}

enum CustomerLabels {
    static let first = "First"
    static let phone = "Phone"
    static let contractor = "Contractor"
    static let spouse = "Spouse"
    static let email = "Email"
    static let lastUpdated = "Last Updated"
    static let photo = "Photo"
    static let rating = "Rating"
    static let salesman = "Salesman"
    static let job = "Job"
    static let product = "Product"
    static let quantity = "Quan"
    static let start = "Start"
    static let complete = "Complete"
    static let saleDate = "Sale Date:"
    static let customerNews = CustomerConfiguration.customerNews
}

enum CustomerFormatters {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd yyyy"
        return formatter
    }()

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
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
        pickRate.append(contentsOf: [
            "5", "4", "1"
        ])
    }
}
