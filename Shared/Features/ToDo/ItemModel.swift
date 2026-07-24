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

    init(id: String = UUID().uuidString, title: String, notes: String = "", isCompleted: Bool) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
    }

    // Custom decoder so existing saved items without `notes` still load fine.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCompleted = try c.decode(Bool.self, forKey: .isCompleted)
    }

    func updateCompletion() -> ItemModel {
        ItemModel(id: id, title: title, notes: notes, isCompleted: !isCompleted)
    }

    func updatingContent(title: String, notes: String) -> ItemModel {
        ItemModel(id: id, title: title, notes: notes, isCompleted: isCompleted)
    }
}
