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

    // Sections grouped by category — only populated when no categoryFilter is set.
    // Stored alongside displayedItems so the view never re-filters on access.
    private(set) var displayedSections: [(header: String, items: [CustomerItem])] = []

    // Total records for the current route — scoped to categoryFilter when set.
    // Stored so the view never triggers an O(n) filter on every access.
    private(set) var totalCount: Int = 0

    private func recomputeDisplayedItems() {
        totalCount = categoryFilter.map { f in allItems.filter { f.matches($0.category) }.count } ?? allItems.count

        let filteredItems = filteredItems(from: allItems)

        switch selectedSort {
        case .date:
            displayedItems = filteredItems.sorted { $0.creationDate > $1.creationDate }
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

        recomputeDisplayedSections()
    }

    private func recomputeDisplayedSections() {
        guard categoryFilter == nil else {
            displayedSections = []
            return
        }
        var sections: [(header: String, items: [CustomerItem])] = []
        for cat in CustomerItem.Category.allCases {
            let catItems = displayedItems.filter { cat.matches($0.category) }
            if !catItems.isEmpty {
                sections.append((header: cat.listTitle, items: catItems))
            }
        }
        let uncategorized = displayedItems.filter { item in
            !CustomerItem.Category.allCases.contains(where: { $0.matches(item.category) })
        }
        if !uncategorized.isEmpty {
            sections.append((header: "Other", items: uncategorized))
        }
        displayedSections = sections
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
