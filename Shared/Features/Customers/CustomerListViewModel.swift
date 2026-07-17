//
//  CustomerListViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

// Presentation state for the customer list: search, Active-only filter, and sorting.
// Owns the derived `displayedItems` collection, recomputed only when an input
// changes so view bodies never filter/sort inline.
@MainActor
@Observable
final class CustomerListViewModel {
    enum SortType: String, CaseIterable, Identifiable {
        case date = "Date"
        case name = "Name"
        case location = "Location"
        case active = "Active"

        var id: Self { self }

        var systemImage: String {
            switch self {
            case .date: return "clock"
            case .name: return "person"
            case .location: return "location"
            case .active: return "folder"
            }
        }
    }

    // Route-level filter matched against the customer's Firestore category
    // (e.g. the Leads menu route shows only "Lead" records). Nil shows all.
    let categoryFilter: CustomerItem.Category?

    init(categoryFilter: CustomerItem.Category? = nil) {
        self.categoryFilter = categoryFilter
    }

    // Inputs: any change recomputes the displayed collection.
    var allItems: [CustomerItem] = [] {
        didSet { recomputeDisplayedItems() }
    }
    var searchText = "" {
        didSet { recomputeDisplayedItems() }
    }
    var isActiveOnly = false {
        didSet { recomputeDisplayedItems() }
    }
    var selectedSort: SortType = .date {
        didSet { recomputeDisplayedItems() }
    }

    // Derived collection: already filtered and sorted, ready for ForEach.
    private(set) var displayedItems: [CustomerItem] = []

    private func recomputeDisplayedItems() {
        let filteredItems = filteredItems(from: allItems)

        switch selectedSort {
        case .date:
            displayedItems = filteredItems
        case .name:
            displayedItems = filteredItems.sorted {
                $0.lastname.localizedCaseInsensitiveCompare($1.lastname) == .orderedAscending
            }
        case .location:
            displayedItems = filteredItems.sorted {
                $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending
            }
        case .active:
            displayedItems = filteredItems.sorted { $0.isActive && !$1.isActive }
        }
    }

    private func filteredItems(from items: [CustomerItem]) -> [CustomerItem] {
        var items = items
        if let categoryFilter {
            items = items.filter { categoryFilter.matches($0.category) }
        }

        let activeFilteredItems = isActiveOnly ? items.filter(\.isActive) : items
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return activeFilteredItems }

        return activeFilteredItems.filter {
            $0.lastname.localizedCaseInsensitiveContains(query) ||
            $0.first.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
    }
}
