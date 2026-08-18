//
//  LeadDetailFieldData.swift
//  TheLightUI
//

import SwiftUI

extension LeadDetailUI {

    var isLead: Bool { CustomerItem.Category.lead.matches(detail.category) }
    var isEmployee: Bool { CustomerItem.Category.employee.matches(detail.category) }
    var isVendor: Bool { CustomerItem.Category.vendor.matches(detail.category) }
    var isCustomer: Bool { CustomerItem.Category.customer.matches(detail.category) }

    // Flatten the domain model into label/value rows for display.
    // Employees and vendors get dedicated field sets with their own labels.
    // For leads, contractor and completion date are hidden (not applicable to the lead lifecycle).
    var detailFields: [CustomerDetailField] {
        if isEmployee { return employeeDetailFields }
        if isVendor { return vendorDetailFields }

        var fields = [
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.street, label: "Street"),
            CustomerDetailField(name: detail.city, label: "City"),
            CustomerDetailField(name: detail.state, label: "State"),
            CustomerDetailField(name: detail.zip, label: "Zip"),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.contractor, label: CustomerLabels.contractor),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.spouse),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.adNo),
            CustomerDetailField(name: detail.salesman, label: CustomerLabels.salesman),
            CustomerDetailField(name: detail.job, label: CustomerLabels.job),
            CustomerDetailField(name: detail.product, label: CustomerLabels.product),
            CustomerDetailField(name: "\(detail.quantity)", label: CustomerLabels.quantity),
            CustomerDetailField(name: detail.formattedCreationDate, label: "Sale Date"),
            CustomerDetailField(name: detail.formattedStartDate, label: isLead ? CustomerLabels.aptDate : CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.callback),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
        if isLead {
            fields.removeAll { $0.label == CustomerLabels.contractor || $0.label == CustomerLabels.complete || $0.label == CustomerLabels.first || $0.label == CustomerLabels.rating }
            fields += [
                CustomerDetailField(name: detail.leadStatus, label: CustomerLabels.leadStatus),
                CustomerDetailField(name: detail.lastContactDate, label: CustomerLabels.lastContactDate),
                CustomerDetailField(name: detail.contactAttempts == 0 ? "" : "\(detail.contactAttempts)", label: CustomerLabels.contactAttempts)
            ]
        }
        if isCustomer {
            fields.removeAll { $0.label == CustomerLabels.first || $0.label == CustomerLabels.rating }
            fields += [
                CustomerDetailField(name: detail.companyName, label: CustomerLabels.companyName),
                CustomerDetailField(name: detail.leadSource, label: CustomerLabels.leadSource),
                CustomerDetailField(name: detail.paymentStatus, label: CustomerLabels.paymentStatus),
                CustomerDetailField(name: detail.paymentTerms, label: CustomerLabels.paymentTerms)
            ]
        }
        return fields
    }

    // Employee records store their specific data in repurposed CustomerItem fields;
    // this list uses the correct labels for each slot.
    var employeeDetailFields: [CustomerDetailField] {
        var fields = [
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.socialSecurity),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.department),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.middle),
            CustomerDetailField(name: detail.formattedStartDate, label: CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.endDate),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.callback),
            CustomerDetailField(name: detail.birthDate, label: CustomerLabels.birthDate),
            CustomerDetailField(name: detail.driverLicense, label: CustomerLabels.driverLicense),
            CustomerDetailField(name: detail.street, label: "Street"),
            CustomerDetailField(name: detail.city, label: "City"),
            CustomerDetailField(name: detail.state, label: "State"),
            CustomerDetailField(name: detail.zip, label: "Zip"),
            CustomerDetailField(name: detail.formattedCreationDate, label: "Date Added"),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
        let emptyHiddenLabels: Set<String> = [CustomerLabels.middle, CustomerLabels.birthDate, CustomerLabels.driverLicense]
        fields.removeAll { emptyHiddenLabels.contains($0.label) && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        fields += [
            CustomerDetailField(name: detail.payType, label: CustomerLabels.payType),
            CustomerDetailField(name: detail.commissionRate, label: CustomerLabels.commissionRate),
            CustomerDetailField(name: detail.userRole, label: CustomerLabels.userRole),
            CustomerDetailField(name: detail.lastLogin, label: CustomerLabels.lastLogin)
        ]
        return fields
    }

    // Vendor records store their specific data in repurposed CustomerItem fields;
    // first holds the company/vendor name (schema has no first/lastname).
    var vendorDetailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.website),
            CustomerDetailField(name: detail.lastname, label: CustomerLabels.profession),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.manager),
            CustomerDetailField(name: detail.salesman, label: CustomerLabels.callback),
            CustomerDetailField(name: detail.paymentTerms, label: CustomerLabels.paymentTerms),
            CustomerDetailField(name: detail.taxId, label: CustomerLabels.taxId),
            CustomerDetailField(name: detail.accountNumber, label: CustomerLabels.accountNumber),
            CustomerDetailField(name: detail.street, label: "Street"),
            CustomerDetailField(name: detail.city, label: "City"),
            CustomerDetailField(name: detail.state, label: "State"),
            CustomerDetailField(name: detail.zip, label: "Zip"),
            CustomerDetailField(name: detail.formattedCreationDate, label: "Date Added"),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }
}
