//
//  CustomerListViewModel.swift
//  TheLightUI
//

import Foundation

@MainActor
final class CustomerListViewModel: ObservableObject {
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

    @Published var searchText = ""
    @Published var isActiveOnly = false
    @Published var selectedSort: SortType = .date

    func displayedItems(from items: [CustomerItem]) -> [CustomerItem] {
        let filteredItems = filteredItems(from: items)

        switch selectedSort {
        case .date:
            return filteredItems
        case .name:
            return filteredItems.sorted {
                $0.lastname.localizedCaseInsensitiveCompare($1.lastname) == .orderedAscending
            }
        case .location:
            return filteredItems.sorted {
                $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending
            }
        case .active:
            return filteredItems.sorted { $0.isActive && !$1.isActive }
        }
    }

    private func filteredItems(from items: [CustomerItem]) -> [CustomerItem] {
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
