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
    let notes: String
    let isCompleted: Bool
    let createdAt: Date

    init(id: String = UUID().uuidString, title: String, notes: String = "", isCompleted: Bool, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    // Custom decoder so existing saved items without `notes` or `createdAt` still load fine.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        createdAt   = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func updateCompletion() -> ItemModel {
        ItemModel(id: id, title: title, notes: notes, isCompleted: !isCompleted, createdAt: createdAt)
    }

    func updatingContent(title: String, notes: String) -> ItemModel {
        ItemModel(id: id, title: title, notes: notes, isCompleted: isCompleted, createdAt: createdAt)
    }
}
