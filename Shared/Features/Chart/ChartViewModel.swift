//
//  ChartViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class ChartViewModel {
    private let customerData: CustomerData
    // Same job/product/salesman/contractor lists the customer form's pickers use,
    // so chart labels match CustomerUI.
    @ObservationIgnored private let pickerData = PickerDataModel()

    init(customerService: CustomerServicing = FirebaseCustomerService()) {
        customerData = CustomerData(customerService: customerService)
    }

    var isLoading: Bool {
        customerData.isLoading
    }

    // Charts only reflect records matching the selected Firestore category
    // (same case-insensitive match as CustomerListViewModel's route filter),
    // so other categories and uncategorized docs are excluded from every chart.
    var categoryFilter = "Customer"

    // The non-empty category values from the customer form's picker.
    var categoryOptions: [String] {
        pickerData.pickCategory.filter { !$0.isEmpty }
    }

    private var customerItems: [CustomerItem] {
        customerData.items.filter { $0.category.caseInsensitiveCompare(categoryFilter) == .orderedSame }
    }

    var hasCustomers: Bool {
        !customerItems.isEmpty
    }

    var customerCount: Int {
        customerItems.count
    }

    var formattedTotalAmount: String {
        ChartFormatters.currency(customerItems.reduce(0) { $0 + $1.amount })
    }

    var monthlySales: [CustomerSalesMonth] {
        CustomerSalesMonth.monthlyTotals(from: customerItems)
    }

    var jobTotals: [ChartItem] {
        amountTotals(groupedBy: \.jobIndex, names: pickerData.pickJob)
    }

    var productTotals: [ChartItem] {
        amountTotals(groupedBy: \.productIndex, names: pickerData.pickProduct)
    }

    var salesmanTotals: [ChartItem] {
        amountTotals(groupedBy: \.salesIndex, names: pickerData.pickSalesman)
    }

    var contractorTotals: [ChartItem] {
        amountTotals(groupedBy: \.contractorIndex, names: pickerData.pickContractor)
    }

    // Customer amounts summed per category (picker index mapped through the picker's name list).
    private func amountTotals(groupedBy indexPath: KeyPath<CustomerItem, Int>, names: [String]) -> [ChartItem] {
        Dictionary(grouping: customerItems) { item -> String in
            let index = item[keyPath: indexPath]
            guard names.indices.contains(index), !names[index].isEmpty else {
                return "None"
            }
            return names[index]
        }
        .map { name, items in
            ChartItem(type: name, value: Double(items.reduce(0) { $0 + $1.amount }))
        }
        .sorted { $0.value > $1.value }
    }
}
