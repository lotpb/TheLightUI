//
//  CustomerPresentation.swift
//  TheLightUI
//

import Foundation

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

extension CustomerItem {
    var address: String {
        [city, state, zip].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var formattedAmount: String {
        CustomerPresentationFormatters.currency.string(from: NSNumber(value: amount)) ?? "$0"
    }

    var formattedCreationDate: String {
        CustomerPresentationFormatters.mediumDate.string(from: creationDate)
    }

    var formattedLastUpdateDate: String {
        CustomerPresentationFormatters.mediumDate.string(from: lastUpdateDate)
    }

    var formattedStartDate: String {
        CustomerPresentationFormatters.mediumDate.string(from: startDate)
    }

    var formattedCompletionDate: String {
        CustomerPresentationFormatters.mediumDate.string(from: completionDate)
    }
}

enum CustomerPresentationFormatters {
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
