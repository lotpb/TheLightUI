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
    
    private let itemsKey = "items_list"
    private let legacyItemsKey = "items_liat"
    
    init() {
        getItems()
    }
    
    func getItems() {
        guard let savedItems = loadSavedItems() else { return }
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
        if let encodedData = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encodedData, forKey: itemsKey)
        }
    }
    
    private func loadSavedItems() -> [ItemModel]? {
        let defaults = UserDefaults.standard
        let data = defaults.data(forKey: itemsKey) ?? defaults.data(forKey: legacyItemsKey)
        guard let data else { return nil }
        return try? JSONDecoder().decode([ItemModel].self, from: data)
    }
}
