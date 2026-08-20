//
//  CustomerPresentation.swift
//  TheLightUI
//

import Foundation

struct CustomerDetailField: Identifiable {
    // Labels are unique per detail screen, so they provide a stable identity
    // across body evaluations (a fresh UUID here would reset row identity on every update).
    var id: String { label }
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
    static let callback = "Callback"
    static let adNo = "Advertiser"
    static let aptDate = "Apt Date"
    static let startDate = "Start Date"
    static let customerNews = "Check our new line of fabulous windows and siding."
    // Employee-specific labels (fields are stored in repurposed CustomerItem slots).
    static let title = "Title"
    static let department = "Department"
    static let manager = "Manager"
    static let middle = "Middle"
    static let company = "Company"
    static let socialSecurity = "Social Security"
    static let birthDate = "Birth Date"
    static let driverLicense = "Driver License"
    static let endDate = "Termination"
    // Vendor-specific labels (fields are stored in repurposed CustomerItem slots).
    static let vendorName = "Vendor"
    static let website = "Web Page"
    static let profession = "Profession"
    static let assistant = "Assistant"
    static let vendorCategory = "Category"
    static let paymentTerms = "Payment Terms"
    static let taxId = "Tax ID"
    static let accountNumber = "Account #"
    // Lead-specific labels.
    static let leadStatus = "Lead Status"
    static let lastContactDate = "Last Contact"
    static let contactAttempts = "Attempts"
    // Customer-specific labels.
    static let companyName = "Company"
    static let leadSource = "Lead Source"
    static let paymentStatus = "Payment Status"
    // Employee-specific extended labels.
    static let payType = "Pay Type"
    static let commissionRate = "Commission"
    static let userRole = "Role"
    static let lastLogin = "Last Login"
    static let employeeStatus = "Emp Status"
    // Common extended labels.
    static let followUpDate = "Follow Up"
    static let tags = "Tags"
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
        startDate <= Date.distantPast.addingTimeInterval(86400) ? "" : CustomerPresentationFormatters.mediumDate.string(from: startDate)
    }

    var formattedCompletionDate: String {
        completionDate <= Date.distantPast.addingTimeInterval(86400) ? "" : CustomerPresentationFormatters.mediumDate.string(from: completionDate)
    }

    var formattedBirthDate: String {
        CustomerPresentationFormatters.parsedBirthDate(from: birthDate)
    }
}

enum CustomerPresentationFormatters {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d yy"
        return formatter
    }()

    private static let birthDateInputFormats = ["MM/dd/yyyy", "M/d/yyyy", "yyyy-MM-dd"]
    private static let birthDateInputParsers: [DateFormatter] = birthDateInputFormats.map {
        let f = DateFormatter(); f.dateFormat = $0; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }

    static func parsedBirthDate(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0000-00-00" else { return trimmed }
        for parser in birthDateInputParsers {
            if let date = parser.date(from: trimmed) {
                return mediumDate.string(from: date)
            }
        }
        return trimmed
    }

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
