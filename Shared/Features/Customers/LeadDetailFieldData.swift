//
//  LeadDetailFieldData.swift
//  TheLightUI
//

import SwiftUI

extension LeadDetailUI {

    var isLead: Bool { CustomerItem.Category.lead.matches(detail.category) }
    var isEmployee: Bool { CustomerItem.Category.employee.matches(detail.category) }
    var isVendor: Bool { CustomerItem.Category.vendor.matches(detail.category) }

    // Flatten the domain model into label/value rows for display.
    // Employees and vendors get dedicated field sets with their own labels.
    // For leads, contractor and completion date are hidden (not applicable to the lead lifecycle).
    var detailFields: [CustomerDetailField] {
        if isEmployee { return employeeDetailFields }
        if isVendor { return vendorDetailFields }

        var fields = [
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickContractor, at: detail.contractorIndex), label: CustomerLabels.contractor),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.spouse),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickSalesman, at: detail.salesIndex), label: CustomerLabels.salesman),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickJob, at: detail.jobIndex), label: CustomerLabels.job),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickProduct, at: detail.productIndex), label: CustomerLabels.product),
            CustomerDetailField(name: "\(detail.quantity)", label: CustomerLabels.quantity),
            CustomerDetailField(name: detail.formattedStartDate, label: isLead ? CustomerLabels.aptDate : CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.callback),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.adNo),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
        if isLead {
            fields.removeAll { $0.label == CustomerLabels.contractor || $0.label == CustomerLabels.complete }
        } else {
            fields.removeAll { $0.label == CustomerLabels.callback }
        }
        return fields
    }

    // Employee records store their specific data in repurposed CustomerItem fields;
    // this list uses the correct labels for each slot.
    var employeeDetailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.socialSecurity),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.department),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.middle),
            CustomerDetailField(name: detail.formattedStartDate, label: CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }

    // Vendor records store their specific data in repurposed CustomerItem fields;
    // first holds the company/vendor name (schema has no first/lastname).
    var vendorDetailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.category, label: CustomerLabels.vendorCategory),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.website),
            CustomerDetailField(name: detail.lastname, label: CustomerLabels.profession),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.manager),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }

    // Safely look up a value by index in a picklist.
    func pickerValue(_ values: [String], at index: Int) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }
}
