//
//  ChatMessage.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/9/21.
//

import Foundation
import FirebaseFirestore

enum ChatMessageType: String, Codable {
    case text
    case image
}

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId: String
    let toId: String
    let text: String
    let timestamp: Date
    let messageType: ChatMessageType

    enum CodingKeys: String, CodingKey {
        case id
        case fromId
        case toId
        case text
        case timestamp
        case messageType
    }

    init(
        id: String? = nil,
        fromId: String,
        toId: String,
        text: String,
        timestamp: Date,
        messageType: ChatMessageType = .text
    ) {
        self.id = id
        self.fromId = fromId
        self.toId = toId
        self.text = text
        self.timestamp = timestamp
        self.messageType = messageType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        fromId = try container.decode(String.self, forKey: .fromId)
        toId = try container.decode(String.self, forKey: .toId)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        messageType = try container.decodeIfPresent(ChatMessageType.self, forKey: .messageType) ?? .text
    }

    var sentDateText: String {
        MessageDateFormatting.weekdayAndTime(for: timestamp)
    }
}
