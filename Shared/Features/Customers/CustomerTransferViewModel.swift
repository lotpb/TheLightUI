//
//  CustomerTransferViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

// Handles JSON backup import/export for the customer list: file-picker
// presentation state, encoding/decoding, and the Firestore upsert loop.
@MainActor
@Observable
final class CustomerTransferViewModel {
    // Presentation state bound from the view (file pickers and result alert).
    var isImporting = false
    var isExporting = false
    var isShowingAlert = false
    private(set) var alertMessage: String?
    private(set) var exportDocument: CustomerJSONDocument?

    @ObservationIgnored private let formService: CustomerFormServicing

    init(formService: CustomerFormServicing) {
        self.formService = formService
    }

    // Encode the given customer list and present the file exporter.
    func startExport(items: [CustomerItem]) {
        do {
            exportDocument = CustomerJSONDocument(data: try CustomerJSONTransfer.exportData(for: items))
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

    // Read the picked file and hand its decoded records to the importer.
    // `existingItems` distinguishes updates from inserts in the result message.
    func handleImport(_ result: Result<URL, Error>, existingItems: [CustomerItem]) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            importRecords(
                try CustomerJSONTransfer.decodeRecords(from: data),
                existingIDs: Set(existingItems.map(\.id))
            )
        } catch {
            showAlert("Import failed: \(error.localizedDescription)")
        }
    }

    // Upserts imported records into Firestore. Records that keep their exported
    // document id overwrite the matching document, so re-importing a backup
    // restores edits instead of duplicating customers. The snapshot listener
    // refreshes the list automatically once the writes land.
    private func importRecords(_ records: [CustomerJSONRecord], existingIDs: Set<String>) {
        Task {
            var inserted = 0
            var updated = 0
            do {
                for record in records {
                    let item = record.customerItem
                    let payload = CustomerFormPayload(
                        customer: item,
                        amount: item.amount,
                        quantity: item.quantity,
                        rate: item.rate,
                        creationDate: item.creationDate,
                        startDate: item.startDate,
                        completionDate: item.completionDate,
                        lastUpdateDate: item.lastUpdateDate,
                        userId: formService.currentUserId
                    )
                    if item.id.isEmpty {
                        _ = try await formService.addCustomer(payload)
                        inserted += 1
                    } else {
                        try await formService.updateCustomer(id: item.id, payload: payload)
                        if existingIDs.contains(item.id) {
                            updated += 1
                        } else {
                            inserted += 1
                        }
                    }
                }
                showAlert(importMessage(inserted: inserted, updated: updated))
            } catch {
                showAlert("Import failed after \(inserted + updated) of \(records.count) customers: \(error.localizedDescription)")
            }
        }
    }

    private func importMessage(inserted: Int, updated: Int) -> String {
        switch (inserted, updated) {
        case (0, 0):
            return "No customers found in this file."
        case (_, 0):
            return "Imported \(inserted) customer\(inserted == 1 ? "" : "s")."
        case (0, _):
            return "Updated \(updated) existing customer\(updated == 1 ? "" : "s")."
        default:
            return "Imported \(inserted) new and updated \(updated) existing customer\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
