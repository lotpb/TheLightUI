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
