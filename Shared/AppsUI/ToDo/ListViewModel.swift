//
//  ListViewModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import Foundation


class ListViewModel: ObservableObject {
    
    @Published var items: [ItemModel] = [] {
        didSet {
            saveItems()
        }
    }
    
    private let itemStore: ItemStoring
    
    init(itemStore: ItemStoring) {
        self.itemStore = itemStore
        getItems()
    }
    
    func getItems() {
        guard let savedItems = itemStore.loadItems() else { return }
        items = savedItems
    }
    
    func deleteItem(at indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
    }
    
    func moveItem(from index: IndexSet, toIndex: Int) {
        items.move(fromOffsets: index, toOffset: toIndex)
    }
    
    func addItem(title: String) {
        let newItem = ItemModel(title: title, isCompleted: false)
        items.append(newItem)
    }

    func updateItem(item: ItemModel) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item.updateCompletion()
        }
    }
    
    private func saveItems() {
        itemStore.saveItems(items)
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
