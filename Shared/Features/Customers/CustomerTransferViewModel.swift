//
//  CustomerTransferViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

// Handles JSON backup import/export for the customer list.
@MainActor
@Observable
final class CustomerTransferViewModel {
    var isImporting = false
    var isExporting = false
    var isShowingAlert = false
    private(set) var alertMessage: String?
    private(set) var exportDocument: CustomerJSONDocument?
    // True while an import's Firestore writes are in flight; prevents overlapping imports.
    private(set) var isTransferring = false

    @ObservationIgnored private let formService: CustomerFormServicing

    init(formService: CustomerFormServicing) {
        self.formService = formService
    }

    func startExport(items: [CustomerItem]) {
        do {
            exportDocument = CustomerJSONDocument(data: try CustomerJSONTransfer.exportData(for: items))
            isExporting = true
        } catch {
            showAlert("Export failed: \(error.localizedDescription)")
        }
    }

    func finishExport(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            showAlert("Export failed: \(error.localizedDescription)")
        }
    }

    // Reads the picked file and either writes it to the local JSON store (device
    // mode) or upserts the records into Firestore (Firebase mode). `onLocalComplete`
    // is called after a successful device-mode write so the caller can refresh
    // the customer store without requiring a pull-to-refresh.
    func handleImport(_ result: Result<URL, Error>, existingItems: [CustomerItem], onLocalComplete: (() -> Void)? = nil) {
        guard !isTransferring else { return }

        if !AppDataStorage.isFirebase {
            isTransferring = true
            Task {
                defer { isTransferring = false }
                do {
                    let url = try result.get()
                    let records = try await Self.loadRecords(from: url)
                    let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(LocalJSONCustomerService.fileName)
                    let data = try CustomerJSONTransfer.exportData(for: records.map(\.customerItem))
                    try data.write(to: fileURL, options: .atomic)
                    onLocalComplete?()
                    showAlert("Imported \(records.count) customer\(records.count == 1 ? "" : "s") to device.")
                } catch {
                    showAlert("Import failed: \(error.localizedDescription)")
                }
            }
            return
        }

        // Firebase mode: upsert into Firestore.
        // setData without a uid strips the field from every existing document; require sign-in.
        guard let userId = formService.currentUserId else {
            showAlert("Sign in before importing customers.")
            return
        }
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
            if didStartAccess { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try CustomerJSONTransfer.decodeRecords(from: data)
    }

    // Firestore caps write batches at 500 operations.
    private static let batchLimit = 500

    private func upsertItems(_ items: [CustomerItem], existingIDs: Set<String>, userId: String, noun: String) async {
        // Batches are all-or-nothing, so derive insert/update counts up front.
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

    func backUp(items: [CustomerItem]) {
        guard !isTransferring else { return }
        guard let userId = formService.currentUserId else {
            showAlert("Sign in before backing up customers.")
            return
        }
        isTransferring = true
        Task {
            defer { isTransferring = false }
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
                showAlert("Backed up \(items.count) customer\(items.count == 1 ? "" : "s") to Firebase.")
            } catch {
                showAlert("Backup failed after \(committed) of \(items.count) customers: \(error.localizedDescription)")
            }
        }
    }

    func showSyncMessage(_ message: String) {
        showAlert(message)
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
