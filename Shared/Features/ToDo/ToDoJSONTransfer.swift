//
//  ToDoJSONTransfer.swift
//  TheLightUI (iOS)
//

import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

// JSON encoding/decoding for to-do items, matching the customer/message
// transfer format (pretty-printed output so exported files are readable).
enum ToDoJSONTransfer {
    static func exportData(for items: [ItemModel]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(items)
    }

    static func decodeItems(from data: Data) throws -> [ItemModel] {
        try JSONDecoder().decode([ItemModel].self, from: data)
    }
}

// Wraps exported to-do JSON for use with `fileExporter`.
struct ToDoJSONDocument: FileDocument {
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

// Handles JSON import/export for the to-do list: file-picker presentation
// state, encoding/decoding, and reporting results through an alert.
@MainActor
@Observable
final class ToDoTransferViewModel {
    // Presentation state bound from the view (file pickers and result alert).
    var isImporting = false
    var isExporting = false
    var isShowingAlert = false
    private(set) var alertMessage: String?
    private(set) var exportDocument: ToDoJSONDocument?

    // Encode the given items and present the file exporter.
    func startExport(items: [ItemModel]) {
        do {
            exportDocument = ToDoJSONDocument(data: try ToDoJSONTransfer.exportData(for: items))
            isExporting = true
        } catch {
            showAlert("Export failed: \(error.localizedDescription)")
        }
    }

    // Surface any error reported by the file exporter.
    func finishExport(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            showAlert("Export failed: \(error.localizedDescription)")
        }
    }

    // Read the picked file, decode its items, and hand them to `merge`,
    // which reports how many were inserted vs updated in the list.
    func handleImport(
        _ result: Result<URL, Error>,
        merge: ([ItemModel]) -> (inserted: Int, updated: Int)
    ) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            let items = try ToDoJSONTransfer.decodeItems(from: data)
            let counts = merge(items)
            showAlert(importMessage(inserted: counts.inserted, updated: counts.updated))
        } catch {
            showAlert("Import failed: \(error.localizedDescription)")
        }
    }

    // Present a Firebase back-up or restore outcome through the same alert
    // used for JSON transfers.
    func showSyncMessage(_ message: String) {
        showAlert(message)
    }

    func showMergeResult(inserted: Int, updated: Int) {
        showAlert(importMessage(inserted: inserted, updated: updated))
    }

    private func importMessage(inserted: Int, updated: Int) -> String {
        switch (inserted, updated) {
        case (0, 0):
            return "No items found in this file."
        case (_, 0):
            return "Imported \(inserted) item\(inserted == 1 ? "" : "s")."
        case (0, _):
            return "Updated \(updated) existing item\(updated == 1 ? "" : "s")."
        default:
            return "Imported \(inserted) new and updated \(updated) existing item\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
