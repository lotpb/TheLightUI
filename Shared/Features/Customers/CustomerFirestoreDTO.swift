//
//  CustomerFirestoreDTO.swift
//  TheLightUI
//

import Foundation
import FirebaseFirestore

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
            CustomerFirestoreSchema.Field.active: isActive ? "1" : "0",
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
