//
//  CustomerFirestore.swift
//  TheLightUI
//

// Firestore schema constants, document-to-model mapping, and the write payload
// for the Customers collection.

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
        static let salesman = "salesman"
        static let job = "job"
        static let product = "product"
        static let street = "street"
        static let city = "city"
        static let state = "state"
        static let zip = "zip"
        static let phone = "phone"
        static let amount = "amount"
        static let email = "email"
        static let rate = "rate"
        static let quantity = "quan"
        static let comments = "comments"
        static let spouse = "spouse"
        static let photo = "photo"
        static let start = "start"
        static let completion = "completion"
        static let lastUpdate = "lastUpdate"
        static let creationDate = "creationDate"
        static let uid = "uid"
        static let companyId = "companyId"
        static let category = "category"
        static let callback = "callback"
        static let adNo = "adNo"
        static let birthDate = "birthDate"
        static let driverLicense = "driverLicense"
        static let companyName = "companyName"
        static let leadSource = "leadSource"
        static let paymentStatus = "paymentStatus"
        static let paymentTerms = "paymentTerms"
        static let leadStatus = "leadStatus"
        static let lastContactDate = "lastContactDate"
        static let contactAttempts = "contactAttempts"
        static let taxId = "taxId"
        static let accountNumber = "accountNumber"
        static let payType = "payType"
        static let commissionRate = "commissionRate"
        static let userRole = "userRole"
        static let lastLogin = "lastLogin"
    }
}

extension CustomerItem {
    // Maps a Firestore document to the app model, tolerating the legacy
    // schema's mixed value types (string-encoded bools/ints, missing dates).
    init(document: QueryDocumentSnapshot) {
        let fields = CustomerFirestoreSchema.Field.self
        let fallbackDate = Date.distantPast
        let rawStreet = document.stringValue(for: fields.street)
        let street = rawStreet.isEmpty ? document.stringValue(for: "address") : rawStreet
        // adNo may be stored as Int (legacy numeric ad source) or String (picker value).
        let adNoValue: String = {
            if let s = document.get(fields.adNo) as? String { return s }
            if let n = document.get(fields.adNo) as? NSNumber { return n.stringValue }
            return ""
        }()

        self.init(
            id: document.documentID,
            isActive: document.boolValue(for: fields.active),
            first: document.stringValue(for: fields.first),
            lastname: document.stringValue(for: fields.lastname),
            street: street,
            city: document.stringValue(for: fields.city),
            state: document.stringValue(for: fields.state),
            zip: document.stringValue(for: fields.zip),
            amount: document.intValue(for: fields.amount),
            creationDate: document.dateValue(for: fields.creationDate) ?? fallbackDate,
            rate: document.stringValue(for: fields.rate),
            phone: document.stringValue(for: fields.phone),
            comments: document.stringValue(for: fields.comments),
            spouse: document.stringValue(for: fields.spouse),
            email: document.stringValue(for: fields.email),
            contractor: document.stringValue(for: fields.contractor),
            photo: document.stringValue(for: fields.photo),
            lastUpdateDate: document.dateValue(for: fields.lastUpdate) ?? fallbackDate,
            startDate: document.dateValue(for: fields.start) ?? fallbackDate,
            completionDate: document.dateValue(for: fields.completion) ?? fallbackDate,
            quantity: document.intValue(for: fields.quantity),
            salesman: document.stringValue(for: fields.salesman),
            job: document.stringValue(for: fields.job),
            product: document.stringValue(for: fields.product),
            category: document.stringValue(for: fields.category),
            callback: document.stringValue(for: fields.callback),
            adNo: adNoValue,
            birthDate: document.stringValue(for: fields.birthDate),
            driverLicense: document.stringValue(for: fields.driverLicense),
            companyName: document.stringValue(for: fields.companyName),
            leadSource: document.stringValue(for: fields.leadSource),
            paymentStatus: document.stringValue(for: fields.paymentStatus),
            paymentTerms: document.stringValue(for: fields.paymentTerms),
            leadStatus: document.stringValue(for: fields.leadStatus),
            lastContactDate: document.stringValue(for: fields.lastContactDate),
            contactAttempts: document.intValue(for: fields.contactAttempts),
            taxId: document.stringValue(for: fields.taxId),
            accountNumber: document.stringValue(for: fields.accountNumber),
            payType: document.stringValue(for: fields.payType),
            commissionRate: document.stringValue(for: fields.commissionRate),
            userRole: document.stringValue(for: fields.userRole),
            lastLogin: document.stringValue(for: fields.lastLogin)
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

    func dateValue(for field: String) -> Date? {
        (get(field) as? Timestamp)?.dateValue()
    }

    // Handles active stored as Bool true, String "1", or Int 1.
    func boolValue(for field: String) -> Bool {
        if let b = get(field) as? Bool { return b }
        if let s = get(field) as? String { return s == "1" }
        if let n = get(field) as? NSNumber { return n.intValue == 1 }
        return false
    }
}

struct CustomerFormPayload {
    var isActive: Bool
    var first: String
    var lastname: String
    var contractor: String
    var street: String
    var city: String
    var state: String
    var zip: String
    var phone: String
    var amount: Int
    var email: String
    var rate: String
    var salesman: String
    var job: String
    var product: String
    var quantity: Int
    var comments: String
    var spouse: String
    var photo: String
    var startDate: Date
    var completionDate: Date
    var lastUpdateDate: Date
    var creationDate: Date
    var userId: String?
    var category: String
    var callback: String
    var adNo: String
    var birthDate: String
    var driverLicense: String
    var companyName: String
    var leadSource: String
    var paymentStatus: String
    var paymentTerms: String
    var leadStatus: String
    var lastContactDate: String
    var contactAttempts: Int
    var taxId: String
    var accountNumber: String
    var payType: String
    var commissionRate: String
    var userRole: String
    var lastLogin: String

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
        self.contractor = customer.contractor
        self.street = customer.street
        self.city = customer.city
        self.state = customer.state
        self.zip = customer.zip
        self.phone = customer.phone
        self.amount = amount
        self.email = customer.email
        self.rate = rate
        self.salesman = customer.salesman
        self.job = customer.job
        self.product = customer.product
        self.quantity = quantity
        self.comments = customer.comments
        self.spouse = customer.spouse
        self.photo = customer.photo
        self.startDate = startDate
        self.completionDate = completionDate
        self.lastUpdateDate = lastUpdateDate
        self.creationDate = creationDate
        self.userId = userId
        self.category = customer.category
        self.callback = customer.callback
        self.adNo = customer.adNo
        self.birthDate = customer.birthDate
        self.driverLicense = customer.driverLicense
        self.companyName = customer.companyName
        self.leadSource = customer.leadSource
        self.paymentStatus = customer.paymentStatus
        self.paymentTerms = customer.paymentTerms
        self.leadStatus = customer.leadStatus
        self.lastContactDate = customer.lastContactDate
        self.contactAttempts = customer.contactAttempts
        self.taxId = customer.taxId
        self.accountNumber = customer.accountNumber
        self.payType = customer.payType
        self.commissionRate = customer.commissionRate
        self.userRole = customer.userRole
        self.lastLogin = customer.lastLogin
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            CustomerFirestoreSchema.Field.active: CustomerFirestoreFieldValues.activeValue(isActive),
            CustomerFirestoreSchema.Field.first: first,
            CustomerFirestoreSchema.Field.lastname: lastname,
            CustomerFirestoreSchema.Field.contractor: contractor,
            CustomerFirestoreSchema.Field.salesman: salesman,
            CustomerFirestoreSchema.Field.job: job,
            CustomerFirestoreSchema.Field.product: product,
            CustomerFirestoreSchema.Field.street: street,
            CustomerFirestoreSchema.Field.city: city,
            CustomerFirestoreSchema.Field.state: state,
            CustomerFirestoreSchema.Field.zip: zip,
            CustomerFirestoreSchema.Field.phone: phone,
            CustomerFirestoreSchema.Field.amount: amount,
            CustomerFirestoreSchema.Field.email: email,
            CustomerFirestoreSchema.Field.rate: rate,
            CustomerFirestoreSchema.Field.quantity: quantity,
            CustomerFirestoreSchema.Field.comments: comments,
            CustomerFirestoreSchema.Field.spouse: spouse,
            CustomerFirestoreSchema.Field.photo: photo,
            CustomerFirestoreSchema.Field.start: Timestamp(date: startDate),
            CustomerFirestoreSchema.Field.completion: Timestamp(date: completionDate),
            CustomerFirestoreSchema.Field.lastUpdate: Timestamp(date: lastUpdateDate),
            CustomerFirestoreSchema.Field.creationDate: Timestamp(date: creationDate),
            CustomerFirestoreSchema.Field.callback: callback,
            CustomerFirestoreSchema.Field.adNo: adNo,
            CustomerFirestoreSchema.Field.birthDate: birthDate,
            CustomerFirestoreSchema.Field.driverLicense: driverLicense,
            CustomerFirestoreSchema.Field.companyName: companyName,
            CustomerFirestoreSchema.Field.leadSource: leadSource,
            CustomerFirestoreSchema.Field.paymentStatus: paymentStatus,
            CustomerFirestoreSchema.Field.paymentTerms: paymentTerms,
            CustomerFirestoreSchema.Field.leadStatus: leadStatus,
            CustomerFirestoreSchema.Field.lastContactDate: lastContactDate,
            CustomerFirestoreSchema.Field.contactAttempts: contactAttempts,
            CustomerFirestoreSchema.Field.taxId: taxId,
            CustomerFirestoreSchema.Field.accountNumber: accountNumber,
            CustomerFirestoreSchema.Field.payType: payType,
            CustomerFirestoreSchema.Field.commissionRate: commissionRate,
            CustomerFirestoreSchema.Field.userRole: userRole,
            CustomerFirestoreSchema.Field.lastLogin: lastLogin
        ]

        if let userId {
            data[CustomerFirestoreSchema.Field.uid] = userId
        }

        if let cid = CompanySession.companyId, !cid.isEmpty {
            data[CustomerFirestoreSchema.Field.companyId] = cid
        }

        // Only written when present so documents that never had the legacy
        // field aren't given an empty one.
        if !category.isEmpty {
            data[CustomerFirestoreSchema.Field.category] = category
        }

        return data
    }
}
