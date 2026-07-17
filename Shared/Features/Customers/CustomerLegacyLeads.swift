//
//  CustomerLegacyLeads.swift
//  TheLightUI
//

// Reads the legacy Leads node (2015 RTDB export, imported to the Realtime
// Database on 2026-07-09) and maps each record onto CustomerItem so the
// transfer view model can upsert it into the Firestore Customers collection
// with category "Lead".

import Foundation
@preconcurrency import FirebaseDatabase
import os

enum LegacyLeadFetchError: LocalizedError {
    case timedOut

    var errorDescription: String? {
        "Timed out loading legacy leads. Check your connection and try again."
    }
}

protocol LegacyLeadServicing: Sendable {
    func fetchLeads() async throws -> [CustomerItem]
}

final class FirebaseLegacyLeadService: LegacyLeadServicing {
    // GoogleService-Info.plist carries no DATABASE_URL, so the instance URL
    // must be passed explicitly.
    private static let databaseURL = "https://thelightui-default-rtdb.firebaseio.com"
    private static let leadsNode = "Leads"
    private static let fetchTimeout: TimeInterval = 15

    func fetchLeads() async throws -> [CustomerItem] {
        let reference = Database.database(url: Self.databaseURL)
            .reference()
            .child(Self.leadsNode)

        // getData() can report "client offline" before the connection is up;
        // observeSingleEvent waits for the first synced value instead. But it
        // waits *forever* while the connection is down, which would strand the
        // continuation (and the caller's isTransferring flag), so race it
        // against a timeout that tears the observer down and fails the fetch.
        let snapshot = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DataSnapshot, Error>) in
            // Guards against double-resume: whichever of the three callbacks
            // (value, cancel, timeout) fires first wins.
            let hasResumed = OSAllocatedUnfairLock(initialState: false)
            @Sendable func resumeOnce(with result: Result<DataSnapshot, Error>) {
                let shouldResume = hasResumed.withLock { resumed -> Bool in
                    defer { resumed = true }
                    return !resumed
                }
                if shouldResume {
                    continuation.resume(with: result)
                }
            }

            reference.observeSingleEvent(of: .value) { snapshot in
                resumeOnce(with: .success(snapshot))
            } withCancel: { error in
                resumeOnce(with: .failure(error))
            }

            // DatabaseReference predates Sendable but is documented as usable
            // from any thread; the SDK serializes work internally.
            nonisolated(unsafe) let timeoutReference = reference
            DispatchQueue.global().asyncAfter(deadline: .now() + Self.fetchTimeout) {
                // Only this service observes the legacy node, so removing all
                // observers on the reference just cleans up our own.
                timeoutReference.removeAllObservers()
                resumeOnce(with: .failure(LegacyLeadFetchError.timedOut))
            }
        }

        return snapshot.children.allObjects.compactMap { child in
            guard let child = child as? DataSnapshot,
                  let fields = child.value as? [String: Any] else { return nil }
            return CustomerItem(legacyLeadID: child.key, fields: fields)
        }
    }
}

extension CustomerItem {
    // Legacy field names and value types differ from the Firestore schema:
    // address vs street, epoch-second dates, numeric active/zip, and
    // "(null)" placeholder photo strings.
    init(legacyLeadID: String, fields: [String: Any]) {
        func string(_ key: String) -> String {
            if let value = fields[key] as? String { return value }
            if let value = fields[key] as? NSNumber { return value.stringValue }
            return ""
        }
        func int(_ key: String) -> Int {
            if let value = fields[key] as? NSNumber { return value.intValue }
            return Int(string(key)) ?? 0
        }
        func date(_ key: String) -> Date? {
            guard let value = fields[key] as? NSNumber else { return nil }
            return Date(timeIntervalSince1970: value.doubleValue)
        }

        let creationDate = date("creationDate") ?? Date()
        let appointmentDate = date("aptdate") ?? creationDate
        let photo = string("photo")
        // The callback disposition has no Firestore counterpart; keep it in
        // the comments so it isn't lost.
        var comments = string("comments")
        let callback = string("callback")
        if !callback.isEmpty {
            comments = comments.isEmpty ? "Callback: \(callback)" : "\(comments)\nCallback: \(callback)"
        }

        self.init(
            id: legacyLeadID,
            isActive: int("active") == 1,
            first: string("first"),
            lastname: string("lastname"),
            street: string("address"),
            city: string("city"),
            state: string("state"),
            zip: string("zip"),
            amount: int("amount"),
            creationDate: creationDate,
            rate: "",
            phone: string("phone"),
            comments: comments,
            spouse: string("spouse"),
            email: string("email"),
            contractorIndex: 0,
            photo: photo == "(null)" ? "" : photo,
            lastUpdateDate: date("lastUpdate") ?? creationDate,
            startDate: appointmentDate,
            completionDate: appointmentDate,
            quantity: 0,
            salesIndex: int("salesNo"),
            jobIndex: int("jobNo"),
            productIndex: int("prodNo"),
            category: CustomerItem.Category.lead.rawValue
        )
    }
}
