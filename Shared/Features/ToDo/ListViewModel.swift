//
//  ListViewModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import Foundation
import Observation

enum ToDoFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case notCompleted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .completed:
            "Completed"
        case .notCompleted:
            "Not Completed"
        }
    }

    func includes(_ item: ItemModel) -> Bool {
        switch self {
        case .all:
            true
        case .completed:
            item.isCompleted
        case .notCompleted:
            !item.isCompleted
        }
    }
}

@MainActor
@Observable
class ListViewModel {

    var items: [ItemModel] = [] {
        didSet {
            recomputeDerivedState()
            enqueueSave()
            pushToFirebaseIfEnabled()
        }
    }

    /// Suppresses the Firebase push while `items` is being set from a load
    /// (local store or Firebase itself) rather than a user mutation, so
    /// stale local data can't overwrite the remote list on screen open.
    @ObservationIgnored private var isLoadingItems = false

    /// The active filter. Owned by the model so derived state can be cached
    /// and recomputed only when an input changes, rather than on every
    /// `body` evaluation.
    var filter: ToDoFilter = .notCompleted {
        didSet { recomputeDerivedState() }
    }

    /// The items the list should display, prepared once per input change.
    private(set) var visibleItems: [ItemModel] = []

    /// Number of completed items across the whole list (ignores the filter).
    /// Cached so the view body reads a stored Int rather than re-filtering.
    private(set) var completedCount: Int = 0

    /// Plain-text summary of the list suitable for sharing.
    /// Cached so the view body reads a stored String rather than remapping.
    private(set) var shareText: String = "My To Do List is empty."

    @ObservationIgnored private let itemStore: ItemStoring
    /// Retained so it can be cancelled before a newer push supersedes it,
    /// preventing stale snapshots from racing the latest write to Firestore.
    @ObservationIgnored private var pushTask: Task<Void, Never>?
    /// Debounces the UserDefaults write so burst mutations (e.g. rapid toggles,
    /// large imports) coalesce into a single encode+write instead of one per item.
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(itemStore: ItemStoring) {
        self.itemStore = itemStore
        getItems()
    }

    deinit {
        pushTask?.cancel()
        saveTask?.cancel()
    }

    func getItems() {
        guard let savedItems = itemStore.loadItems() else { return }
        isLoadingItems = true
        items = savedItems
        isLoadingItems = false
    }

    /// Pulls items from Firebase and merges them into the list when
    /// "Store Data in Firebase" is enabled in Settings.
    func refreshFromFirebase() async {
        guard AppDataStorage.isFirebase else { return }
        guard let remoteItems = try? await ToDoFirestoreService().fetchAll(), !remoteItems.isEmpty else { return }
        isLoadingItems = true
        _ = importItems(remoteItems)
        isLoadingItems = false
    }

    /// Mirrors the whole list (including deletions) to Firebase after a
    /// user mutation when "Store Data in Firebase" is enabled. A short debounce
    /// collapses burst mutations (e.g. drag-to-reorder) into a single write,
    /// and cancelling the prior task prevents stale snapshots from racing.
    private func pushToFirebaseIfEnabled() {
        guard AppDataStorage.isFirebase, !isLoadingItems else { return }
        let snapshot = items
        pushTask?.cancel()
        pushTask = Task.detached {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            try? await ToDoFirestoreService().replaceAll(snapshot)
        }
    }

    /// Deletes items by offsets into the visible (filtered) collection.
    func deleteItem(at offsets: IndexSet) {
        let ids = Set(offsets.map { visibleItems[$0].id })
        items.removeAll { ids.contains($0.id) }
    }

    func deleteItem(_ item: ItemModel) {
        items.removeAll { $0.id == item.id }
    }

    /// Removes every item from the list.
    func clearAll() {
        items.removeAll()
    }

    /// Sorts the whole list so outstanding items surface first, then
    /// alphabetically by title within each completion state.
    func sortItems() {
        items.sort { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    /// Reorders within the visible subset, then writes the new order back into
    /// `items` without disturbing the positions of items hidden by the filter.
    func moveItem(from source: IndexSet, to destination: Int) {
        var reordered = visibleItems
        reordered.move(fromOffsets: source, toOffset: destination)

        let visibleIDs = Set(visibleItems.map(\.id))
        var iterator = reordered.makeIterator()
        items = items.map { visibleIDs.contains($0.id) ? (iterator.next() ?? $0) : $0 }
    }

    func addItem(title: String, notes: String = "") {
        items.append(ItemModel(title: title, notes: notes, isCompleted: false))
    }

    /// Merges items imported from a JSON backup, replacing items with
    /// matching ids. Returns counts for the import result alert. Assigns
    /// `items` once so the didSet persists the merged list in a single save.
    func importItems(_ importedItems: [ItemModel]) -> (inserted: Int, updated: Int) {
        var inserted = 0
        var updated = 0
        var merged = items
        for item in importedItems {
            if let index = merged.firstIndex(where: { $0.id == item.id }) {
                merged[index] = item
                updated += 1
            } else {
                merged.append(item)
                inserted += 1
            }
        }
        items = merged
        return (inserted, updated)
    }

    func updateItemContent(_ item: ItemModel, title: String, notes: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item.updatingContent(title: title, notes: notes)
        }
    }

    func updateItem(item: ItemModel) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item.updateCompletion()
        }
    }

    /// Single recompute pass for all derived state. Called once per `items`
    /// or `filter` change so the view body reads stored values rather than
    /// re-running filter/map/join on every render.
    private func recomputeDerivedState() {
        var visible: [ItemModel] = []
        var completed = 0
        var lines: [String] = []
        for item in items {
            if filter.includes(item) { visible.append(item) }
            if item.isCompleted { completed += 1 }
            lines.append("\(item.isCompleted ? "✅" : "▢") \(item.title)")
        }
        visibleItems = visible
        completedCount = completed
        shareText = items.isEmpty ? "My To Do List is empty."
            : (["My To Do List", ""] + lines).joined(separator: "\n")
    }

    private func enqueueSave() {
        let snapshot = items
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            self?.itemStore.saveItems(snapshot)
        }
    }
}

protocol ItemStoring {
    func loadItems() -> [ItemModel]?
    func saveItems(_ items: [ItemModel])
}

struct UserDefaultsItemStore: ItemStoring {
    private let defaults: UserDefaults
    private let itemsKey = "items_list"
    private let legacyItemsKey = "items_liat"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadItems() -> [ItemModel]? {
        let data = defaults.data(forKey: itemsKey) ?? defaults.data(forKey: legacyItemsKey)
        guard let data else { return nil }
        return try? JSONDecoder().decode([ItemModel].self, from: data)
    }

    func saveItems(_ items: [ItemModel]) {
        if let encodedData = try? JSONEncoder().encode(items) {
            defaults.set(encodedData, forKey: itemsKey)
        }
    }
}
