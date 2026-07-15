//
//  MessageTransferViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

// Handles JSON import/export for the inbox: file-picker presentation state,
// encoding/decoding, and reporting results through an alert.
@MainActor
@Observable
final class MessageTransferViewModel {
    // Presentation state bound from the view (file pickers and result alert).
    var isImporting = false
    var isExporting = false
    var isShowingAlert = false
    private(set) var alertMessage: String?
    private(set) var exportDocument: MessageJSONDocument?

    // Encode the given messages and present the file exporter.
    func startExport(messages: [RecentMessage]) {
        do {
            exportDocument = MessageJSONDocument(data: try MessageJSONTransfer.exportData(for: messages))
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

    // Read the picked file, decode its messages, and hand them to `merge`,
    // which reports how many were inserted vs updated in the inbox.
    func handleImport(
        _ result: Result<URL, Error>,
        merge: ([RecentMessage]) -> (inserted: Int, updated: Int)
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
            let records = try MessageJSONTransfer.decodeRecords(from: data)
            let counts = merge(records.map(\.recentMessage))
            showAlert(importMessage(inserted: counts.inserted, updated: counts.updated))
        } catch {
            showAlert("Import failed: \(error.localizedDescription)")
        }
    }

    private func importMessage(inserted: Int, updated: Int) -> String {
        switch (inserted, updated) {
        case (0, 0):
            return "No messages found in this file."
        case (_, 0):
            return "Imported \(inserted) message\(inserted == 1 ? "" : "s")."
        case (0, _):
            return "Updated \(updated) existing message\(updated == 1 ? "" : "s")."
        default:
            return "Imported \(inserted) new and updated \(updated) existing message\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
