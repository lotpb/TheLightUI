//
//  MessageJSONTransfer.swift
//  TheLightUI
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Codable snapshot of a recent message used for JSON import/export. Kept
// separate from RecentMessage because @DocumentID only encodes with the
// Firestore coder, so the file format stays plain JSON.
struct MessageJSONRecord: Codable, Equatable {
    var id: String?
    var text: String
    var email: String
    var fromId: String
    var toId: String
    var profileImageUrl: String
    var timestamp: Date

    init(_ message: RecentMessage) {
        id = message.id
        text = message.text
        email = message.email
        fromId = message.fromId
        toId = message.toId
        profileImageUrl = message.profileImageUrl
        timestamp = message.timestamp
    }

    var recentMessage: RecentMessage {
        RecentMessage(
            id: id,
            text: text,
            email: email,
            fromId: fromId,
            toId: toId,
            profileImageUrl: profileImageUrl,
            timestamp: timestamp
        )
    }
}

// JSON encoding/decoding for recent messages, matching the customer transfer
// format (ISO 8601 dates, pretty-printed output).
enum MessageJSONTransfer {
    static func exportData(for messages: [RecentMessage]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(messages.map(MessageJSONRecord.init))
    }

    static func decodeRecords(from data: Data) throws -> [MessageJSONRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MessageJSONRecord].self, from: data)
    }
}

// Wraps exported message JSON for use with `fileExporter`.
struct MessageJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
