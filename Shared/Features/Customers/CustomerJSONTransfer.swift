//
//  CustomerJSONTransfer.swift
//  TheLightUI
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Codable snapshot of a customer used for JSON import/export. Kept separate
// from CustomerItem so the file format stays stable independent of the UI model.
struct CustomerJSONRecord: Codable, Equatable {
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
    var category: String
    var callback: String
    var adNo: String

    init(_ item: CustomerItem) {
        id = item.id
        isActive = item.isActive
        first = item.first
        lastname = item.lastname
        street = item.street
        city = item.city
        state = item.state
        zip = item.zip
        amount = item.amount
        creationDate = item.creationDate
        rate = item.rate
        phone = item.phone
        comments = item.comments
        spouse = item.spouse
        email = item.email
        contractorIndex = item.contractorIndex
        photo = item.photo
        lastUpdateDate = item.lastUpdateDate
        startDate = item.startDate
        completionDate = item.completionDate
        quantity = item.quantity
        salesIndex = item.salesIndex
        jobIndex = item.jobIndex
        productIndex = item.productIndex
        category = item.category
        callback = item.callback
        adNo = item.adNo
    }

    // Custom decoder so JSON files exported before category/callback/adNo was
    // added still import without error.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(String.self, forKey: .id)
        isActive        = try c.decode(Bool.self,   forKey: .isActive)
        first           = try c.decode(String.self, forKey: .first)
        lastname        = try c.decode(String.self, forKey: .lastname)
        street          = try c.decode(String.self, forKey: .street)
        city            = try c.decode(String.self, forKey: .city)
        state           = try c.decode(String.self, forKey: .state)
        zip             = try c.decode(String.self, forKey: .zip)
        amount          = try c.decode(Int.self,    forKey: .amount)
        creationDate    = try c.decode(Date.self,   forKey: .creationDate)
        rate            = try c.decode(String.self, forKey: .rate)
        phone           = try c.decode(String.self, forKey: .phone)
        comments        = try c.decode(String.self, forKey: .comments)
        spouse          = try c.decode(String.self, forKey: .spouse)
        email           = try c.decode(String.self, forKey: .email)
        contractorIndex = try c.decode(Int.self,    forKey: .contractorIndex)
        photo           = try c.decode(String.self, forKey: .photo)
        lastUpdateDate  = try c.decode(Date.self,   forKey: .lastUpdateDate)
        startDate       = try c.decode(Date.self,   forKey: .startDate)
        completionDate  = try c.decode(Date.self,   forKey: .completionDate)
        quantity        = try c.decode(Int.self,    forKey: .quantity)
        salesIndex      = try c.decode(Int.self,    forKey: .salesIndex)
        jobIndex        = try c.decode(Int.self,    forKey: .jobIndex)
        productIndex    = try c.decode(Int.self,    forKey: .productIndex)
        category        = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        callback        = try c.decodeIfPresent(String.self, forKey: .callback) ?? ""
        adNo            = try c.decodeIfPresent(String.self, forKey: .adNo)     ?? ""
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
            category: category,
            callback: callback,
            adNo: adNo
        )
    }
}

// JSON encoding/decoding for customer records, matching the expense
// transfer format (ISO 8601 dates, pretty-printed output).
enum CustomerJSONTransfer {
    static func exportData(for items: [CustomerItem]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(items.map(CustomerJSONRecord.init))
    }

    static func decodeRecords(from data: Data) throws -> [CustomerJSONRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CustomerJSONRecord].self, from: data)
    }
}

// Wraps exported customer JSON for use with `fileExporter`.
struct CustomerJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
