//
//  CustomerTransferViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

// Handles JSON backup import/export and legacy RTDB imports for the customer list.
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

    // Reads the picked file, then upserts its decoded records into Firestore.
    // Records that keep their exported document id overwrite the matching
    // document, so re-importing a backup restores edits instead of duplicating
    // customers. `existingItems` distinguishes updates from inserts in the result message.
    func handleImport(_ result: Result<URL, Error>, existingItems: [CustomerItem]) {
        guard !isTransferring else { return }
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

    func importLegacyLeads(
        existingItems: [CustomerItem],
        leadService: LegacyLeadServicing = FirebaseLegacyLeadService()
    ) {
        performLegacyImport(existingItems: existingItems, noun: "lead") {
            try await leadService.fetchLeads()
        }
    }

    func importLegacyEmployees(
        existingItems: [CustomerItem],
        employeeService: LegacyEmployeeServicing = FirebaseLegacyEmployeeService()
    ) {
        performLegacyImport(existingItems: existingItems, noun: "employee") {
            try await employeeService.fetchEmployees()
        }
    }

    func importLegacyVendors(
        existingItems: [CustomerItem],
        vendorService: LegacyVendorServicing = FirebaseLegacyVendorService()
    ) {
        performLegacyImport(existingItems: existingItems, noun: "vendor") {
            try await vendorService.fetchVendors()
        }
    }

    // Shared pattern for all legacy RTDB imports: sign-in guard, isTransferring flag
    // (set synchronously so double-taps can't slip past), fetch, then upsert.
    private func performLegacyImport(
        existingItems: [CustomerItem],
        noun: String,
        fetch: @escaping @Sendable () async throws -> [CustomerItem]
    ) {
        guard !isTransferring else { return }
        guard let userId = formService.currentUserId else {
            showAlert("Sign in before importing \(noun)s.")
            return
        }
        isTransferring = true
        Task {
            defer { isTransferring = false }
            do {
                let items = try await fetch()
                guard !items.isEmpty else {
                    showAlert("No \(noun)s found.")
                    return
                }
                await upsertItems(items, existingIDs: Set(existingItems.map(\.id)), userId: userId, noun: noun)
            } catch {
                showAlert("\(noun.capitalized) import failed: \(error.localizedDescription)")
            }
        }
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

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }
}
