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
    // True while an import's Firestore writes are in flight; used to prevent
    // overlapping imports (e.g. double-tapping Import Legacy Leads).
    private(set) var isTransferring = false

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

    // Reads the picked file, then upserts its decoded records into Firestore.
    // Records that keep their exported document id overwrite the matching
    // document, so re-importing a backup restores edits instead of duplicating
    // customers. The snapshot listener refreshes the list once the writes land.
    // `existingItems` distinguishes updates from inserts in the result message.
    func handleImport(_ result: Result<URL, Error>, existingItems: [CustomerItem]) {
        guard !isTransferring else { return }
        // The upsert uses a full-document setData, so a payload built without
        // a uid would strip the field from every existing document. Require a
        // signed-in user up front, like the form's save path does.
        guard let userId = formService.currentUserId else {
            showAlert("Sign in before importing customers.")
            return
        }
        // Set synchronously so a second tap can't slip past the guard before
        // the task body runs.
        isTransferring = true
        let existingIDs = Set(existingItems.map(\.id))
        Task {
            defer { isTransferring = false }
            do {
                let url = try result.get()
                let records = try await Self.loadRecords(from: url)
                await upsertItems(records.map(\.customerItem), existingIDs: existingIDs, userId: userId, noun: "customer")
            } catch {
                showAlert("Import failed: \(error.localizedDescription)")
            }
        }
    }

    // nonisolated async so the read runs off the main actor: the picked file
    // can live on iCloud Drive and block while it downloads.
    private nonisolated static func loadRecords(from url: URL) async throws -> [CustomerJSONRecord] {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let data = try Data(contentsOf: url)
        return try CustomerJSONTransfer.decodeRecords(from: data)
    }

    // Pulls the legacy Leads node from the Realtime Database and upserts each
    // record into Firestore with category "Lead", so leads display in the
    // customer list and the Leads menu route. Document ids reuse the lead
    // keys, so re-running the import refreshes instead of duplicating.
    func importLegacyLeads(
        existingItems: [CustomerItem],
        leadService: LegacyLeadServicing = FirebaseLegacyLeadService()
    ) {
        guard !isTransferring else { return }
        // Same signed-in guard as importRecords: setData without a uid would
        // strip the field when a re-run refreshes existing lead documents.
        guard let userId = formService.currentUserId else {
            showAlert("Sign in before importing leads.")
            return
        }
        // Set synchronously so a second tap can't slip past the guard before
        // the task body runs.
        isTransferring = true
        Task {
            defer { isTransferring = false }
            do {
                let leads = try await leadService.fetchLeads()
                guard !leads.isEmpty else {
                    showAlert("No legacy leads found.")
                    return
                }
                await upsertItems(leads, existingIDs: Set(existingItems.map(\.id)), userId: userId, noun: "lead")
            } catch {
                showAlert("Lead import failed: \(error.localizedDescription)")
            }
        }
    }

    // Firestore caps write batches at 500 operations.
    private static let batchLimit = 500

    private func upsertItems(_ items: [CustomerItem], existingIDs: Set<String>, userId: String, noun: String) async {
        // Batches are all-or-nothing, so the insert/update split can be
        // derived up front: empty or unknown ids create documents, known ids
        // overwrite them.
        let inserted = items.count { $0.id.isEmpty || !existingIDs.contains($0.id) }
        let updated = items.count - inserted

        let entries = items.map { item in
            (
                id: item.id,
                payload: CustomerFormPayload(
                    customer: item,
                    amount: item.amount,
                    quantity: item.quantity,
                    rate: item.rate,
                    creationDate: item.creationDate,
                    startDate: item.startDate,
                    completionDate: item.completionDate,
                    lastUpdateDate: item.lastUpdateDate,
                    userId: userId
                )
            )
        }

        var committed = 0
        do {
            for start in stride(from: 0, to: entries.count, by: Self.batchLimit) {
                let chunk = Array(entries[start..<min(start + Self.batchLimit, entries.count)])
                try await formService.upsertCustomersBatch(chunk)
                committed += chunk.count
            }
            showAlert(importMessage(inserted: inserted, updated: updated, noun: noun))
        } catch {
            showAlert("Import failed after \(committed) of \(items.count) \(noun)s: \(error.localizedDescription)")
        }
    }

    private func importMessage(inserted: Int, updated: Int, noun: String) -> String {
        switch (inserted, updated) {
        case (0, 0):
            return "No \(noun)s found in this file."
        case (_, 0):
            return "Imported \(inserted) \(noun)\(inserted == 1 ? "" : "s")."
        case (0, _):
            return "Updated \(updated) existing \(noun)\(updated == 1 ? "" : "s")."
        default:
            return "Imported \(inserted) new and updated \(updated) existing \(noun)\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
