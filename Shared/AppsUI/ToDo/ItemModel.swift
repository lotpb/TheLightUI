//
//  ItemModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import Foundation

struct ItemModel: Identifiable, Codable {
    let id: String
    let title: String
    let isCompleted: Bool
    
    init(id: String = UUID().uuidString, title: String, isCompleted: Bool) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
    
    func updateCompletion() -> ItemModel {
        ItemModel(id: id, title: title, isCompleted: !isCompleted)
    }
}
