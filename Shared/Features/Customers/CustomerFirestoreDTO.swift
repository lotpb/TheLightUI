//
//  CustomerFirestoreDTO.swift
//  TheLightUI
//

import Foundation
import FirebaseFirestore

enum CustomerFirestoreFieldValues {
    static func activeValue(_ isActive: Bool) -> String {
        isActive ? "1" : "0"
    }
}

enum CustomerFirestoreSchema {
    static let collection = "Customers"

    enum Field {
        static let active = "active"
        static let first = "first"
        static let lastname = "lastname"
        static let contractor = "contractor"
        static let street = "street"
        static let city = "city"
        static let state = "state"
        static let zip = "zip"
        static let phone = "phone"
        static let amount = "amount"
        static let email = "email"
        static let rate = "rate"
        static let salesNo = "salesNo"
        static let jobNo = "jobNo"
        static let prodNo = "prodNo"
        static let quantity = "quan"
        static let comments = "comments"
        static let spouse = "spouse"
        static let photo = "photo"
        static let start = "start"
        static let completion = "completion"
        static let lastUpdate = "lastUpdate"
        static let creationDate = "creationDate"
        static let uid = "uid"
    }
}

struct CustomerFirestoreDTO {
    let id: String
    let isActive: Bool
    let first: String
    let lastname: String
    let street: String
    let city: String
    let state: String
    let zip: String
    let amount: Int
    let creationDate: Date
    let rate: String
    let phone: String
    let comments: String
    let spouse: String
    let email: String
    let contractorIndex: Int
    let photo: String
    let lastUpdateDate: Date
    let startDate: Date
    let completionDate: Date
    let quantity: Int
    let salesIndex: Int
    let jobIndex: Int
    let productIndex: Int

    init(document: QueryDocumentSnapshot) {
        let fields = CustomerFirestoreSchema.Field.self
        let fallbackDate = Date()

        id = document.documentID
        isActive = document.stringValue(for: fields.active) == "1"
        first = document.stringValue(for: fields.first)
        lastname = document.stringValue(for: fields.lastname)
        street = document.stringValue(for: fields.street)
        city = document.stringValue(for: fields.city)
        state = document.stringValue(for: fields.state)
        zip = document.stringValue(for: fields.zip)
        amount = document.intValue(for: fields.amount)
        creationDate = document.dateValue(for: fields.creationDate) ?? fallbackDate
        rate = document.stringValue(for: fields.rate)
        phone = document.stringValue(for: fields.phone)
        comments = document.stringValue(for: fields.comments)
        spouse = document.stringValue(for: fields.spouse)
        email = document.stringValue(for: fields.email)
        contractorIndex = document.intStringValue(for: fields.contractor)
        photo = document.stringValue(for: fields.photo)
        lastUpdateDate = document.dateValue(for: fields.lastUpdate) ?? fallbackDate
        startDate = document.dateValue(for: fields.start) ?? fallbackDate
        completionDate = document.dateValue(for: fields.completion) ?? fallbackDate
        quantity = document.intValue(for: fields.quantity)
        salesIndex = document.intValue(for: fields.salesNo)
        jobIndex = document.intValue(for: fields.jobNo)
        productIndex = document.intValue(for: fields.prodNo)
    }

    var customerItem: CustomerItem {
        CustomerItem(
            id: id,
            isActive: isActive,
            first: first,
            lastname: lastname,
            street: street,
            city: city,
            state: state,
            zip: zip,
            amount: amount,
            creationDate: creationDate,
            rate: rate,
            phone: phone,
            comments: comments,
            spouse: spouse,
            email: email,
            contractorIndex: contractorIndex,
            photo: photo,
            lastUpdateDate: lastUpdateDate,
            startDate: startDate,
            completionDate: completionDate,
            quantity: quantity,
            salesIndex: salesIndex,
            jobIndex: jobIndex,
            productIndex: productIndex,
            status: .edit,
            formController: "Customer"
        )
    }
}

private extension QueryDocumentSnapshot {
    func stringValue(for field: String) -> String {
        get(field) as? String ?? ""
    }

    func intValue(for field: String) -> Int {
        if let number = get(field) as? NSNumber {
            return number.intValue
        }

        if let value = get(field) as? Int {
            return value
        }

        return 0
    }

    func intStringValue(for field: String) -> Int {
        Int(stringValue(for: field)) ?? 0
    }

    func dateValue(for field: String) -> Date? {
        (get(field) as? Timestamp)?.dateValue()
    }
}

struct CustomerFormPayload {
    var isActive: Bool
    var first: String
    var lastname: String
    var contractorIndex: Int
    var street: String
    var city: String
    var state: String
    var zip: String
    var phone: String
    var amount: Int
    var email: String
    var rate: String
    var salesIndex: Int
    var jobIndex: Int
    var productIndex: Int
    var quantity: Int
    var comments: String
    var spouse: String
    var photo: String
    var startDate: Date
    var completionDate: Date
    var lastUpdateDate: Date
    var creationDate: Date
    var userId: String?

    init(
        customer: CustomerItem,
        amount: Int,
        quantity: Int,
        rate: String,
        creationDate: Date,
        startDate: Date,
        completionDate: Date,
        lastUpdateDate: Date = Date(),
        userId: String? = nil
    ) {
        self.isActive = customer.isActive
        self.first = customer.first
        self.lastname = customer.lastname
        self.contractorIndex = customer.contractorIndex
        self.street = customer.street
        self.city = customer.city
        self.state = customer.state
        self.zip = customer.zip
        self.phone = customer.phone
        self.amount = amount
        self.email = customer.email
        self.rate = rate
        self.salesIndex = customer.salesIndex
        self.jobIndex = customer.jobIndex
        self.productIndex = customer.productIndex
        self.quantity = quantity
        self.comments = customer.comments
        self.spouse = customer.spouse
        self.photo = customer.photo
        self.startDate = startDate
        self.completionDate = completionDate
        self.lastUpdateDate = lastUpdateDate
        self.creationDate = creationDate
        self.userId = userId
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            CustomerFirestoreSchema.Field.active: CustomerFirestoreFieldValues.activeValue(isActive),
            CustomerFirestoreSchema.Field.first: first,
            CustomerFirestoreSchema.Field.lastname: lastname,
            CustomerFirestoreSchema.Field.contractor: "\(contractorIndex)",
            CustomerFirestoreSchema.Field.street: street,
            CustomerFirestoreSchema.Field.city: city,
            CustomerFirestoreSchema.Field.state: state,
            CustomerFirestoreSchema.Field.zip: zip,
            CustomerFirestoreSchema.Field.phone: phone,
            CustomerFirestoreSchema.Field.amount: amount,
            CustomerFirestoreSchema.Field.email: email,
            CustomerFirestoreSchema.Field.rate: rate,
            CustomerFirestoreSchema.Field.salesNo: salesIndex,
            CustomerFirestoreSchema.Field.jobNo: jobIndex,
            CustomerFirestoreSchema.Field.prodNo: productIndex,
            CustomerFirestoreSchema.Field.quantity: quantity,
            CustomerFirestoreSchema.Field.comments: comments,
            CustomerFirestoreSchema.Field.spouse: spouse,
            CustomerFirestoreSchema.Field.photo: photo,
            CustomerFirestoreSchema.Field.start: Timestamp(date: startDate),
            CustomerFirestoreSchema.Field.completion: Timestamp(date: completionDate),
            CustomerFirestoreSchema.Field.lastUpdate: Timestamp(date: lastUpdateDate),
            CustomerFirestoreSchema.Field.creationDate: Timestamp(date: creationDate)
        ]

        if let userId {
            data[CustomerFirestoreSchema.Field.uid] = userId
        }

        return data
    }
}
