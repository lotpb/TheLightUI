//
//  CustomerLegacyImport.swift
//  TheLightUI
//

// Reads the legacy Leads and Employee nodes (2015 RTDB export) and maps each
// record onto CustomerItem so the transfer view model can upsert it into the
// Firestore Customers collection with the appropriate category.

import Foundation
@preconcurrency import FirebaseDatabase
import os

enum LegacyLeadFetchError: LocalizedError {
    case timedOut

    var errorDescription: String? {
        "Timed out loading legacy leads. Check your connection and try again."
    }
}

// Waits for the first synced RTDB snapshot, racing the SDK's value callback
// against a timeout that removes the observer and fails the continuation.
private func rtdbSnapshot(from reference: DatabaseReference, timeout: TimeInterval) async throws -> DataSnapshot {
    try await withCheckedThrowingContinuation { continuation in
        let hasResumed = OSAllocatedUnfairLock(initialState: false)
        @Sendable func resumeOnce(with result: Result<DataSnapshot, Error>) {
            let shouldResume = hasResumed.withLock { resumed -> Bool in
                defer { resumed = true }
                return !resumed
            }
            if shouldResume { continuation.resume(with: result) }
        }
        reference.observeSingleEvent(of: .value) { snapshot in
            resumeOnce(with: .success(snapshot))
        } withCancel: { error in
            resumeOnce(with: .failure(error))
        }
        Task {
            try? await Task.sleep(for: .seconds(timeout))
            resumeOnce(with: .failure(LegacyLeadFetchError.timedOut))
        }
    }
}

protocol LegacyLeadServicing: Sendable {
    func fetchLeads() async throws -> [CustomerItem]
}

final class FirebaseLegacyLeadService: LegacyLeadServicing, Sendable {
    // GoogleService-Info.plist carries no DATABASE_URL, so the instance URL
    // must be passed explicitly.
    private static let databaseURL = "https://thelightui-default-rtdb.firebaseio.com"
    private static let leadsNode = "Leads"
    private static let fetchTimeout: TimeInterval = 15

    func fetchLeads() async throws -> [CustomerItem] {
        let reference = Database.database(url: Self.databaseURL)
            .reference()
            .child(Self.leadsNode)
        let snapshot = try await rtdbSnapshot(from: reference, timeout: Self.fetchTimeout)
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
        let comments = string("comments")
        let callback = string("callback")

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
            category: CustomerItem.Category.lead.rawValue,
            callback: callback,
            adNo: string("adNo")
        )
    }
}

// MARK: - Employee

protocol LegacyEmployeeServicing: Sendable {
    func fetchEmployees() async throws -> [CustomerItem]
}

final class FirebaseLegacyEmployeeService: LegacyEmployeeServicing, Sendable {
    private static let databaseURL = "https://thelightui-default-rtdb.firebaseio.com"
    private static let employeeNode = "Employee"
    private static let fetchTimeout: TimeInterval = 15

    func fetchEmployees() async throws -> [CustomerItem] {
        let reference = Database.database(url: Self.databaseURL)
            .reference()
            .child(Self.employeeNode)
        let snapshot = try await rtdbSnapshot(from: reference, timeout: Self.fetchTimeout)
        return snapshot.children.allObjects.compactMap { child in
            guard let child = child as? DataSnapshot,
                  let fields = child.value as? [String: Any] else { return nil }
            return CustomerItem(employeeID: child.key, fields: fields)
        }
    }
}

extension CustomerItem {
    // Maps the legacy Employee RTDB node onto CustomerItem.
    // Employee-specific fields are packed into repurposed string slots:
    //   rate     → job title
    //   adNo     → department
    //   callback → manager
    //   spouse   → company/organization
    // Phone priority: cellphone → workphone → homephone.
    init(employeeID: String, fields: [String: Any]) {
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

        // zip is stored as Int in the RTDB export.
        let zip: String = {
            if let s = fields["zip"] as? String, !s.isEmpty { return s }
            if let n = fields["zip"] as? NSNumber { return n.stringValue }
            return ""
        }()

        // Use cell as primary phone; fall back to work then home.
        let phone = [string("cellphone"), string("workphone"), string("homephone")]
            .first { !$0.isEmpty } ?? ""

        let creationDate = date("creationDate") ?? Date()
        let lastUpdate = date("lastUpdate") ?? creationDate

        self.init(
            id: employeeID,
            isActive: int("active") == 1,
            first: string("first"),
            lastname: string("lastname"),
            street: string("address"),
            city: string("city"),
            state: string("state"),
            zip: zip,
            amount: 0,
            creationDate: creationDate,
            rate: string("title"),         // repurposed: job title
            phone: phone,
            comments: string("comments"),
            spouse: string("company"),     // repurposed: company/organization
            email: string("email"),
            contractorIndex: 0,
            photo: string("imageUrl"),
            lastUpdateDate: lastUpdate,
            startDate: creationDate,
            completionDate: creationDate,
            quantity: 0,
            salesIndex: 0,
            jobIndex: 0,
            productIndex: 0,
            category: CustomerItem.Category.employee.rawValue,
            callback: string("manager"),   // repurposed: manager name
            adNo: string("department")     // repurposed: department name
        )
    }
}

// MARK: - Vendor

protocol LegacyVendorServicing: Sendable {
    func fetchVendors() async throws -> [CustomerItem]
}

final class FirebaseLegacyVendorService: LegacyVendorServicing, Sendable {
    private static let databaseURL = "https://thelightui-default-rtdb.firebaseio.com"
    private static let vendorNode = "Vendor"
    private static let fetchTimeout: TimeInterval = 15

    func fetchVendors() async throws -> [CustomerItem] {
        let reference = Database.database(url: Self.databaseURL)
            .reference()
            .child(Self.vendorNode)
        let snapshot = try await rtdbSnapshot(from: reference, timeout: Self.fetchTimeout)
        return snapshot.children.allObjects.compactMap { child in
            guard let child = child as? DataSnapshot,
                  let fields = child.value as? [String: Any] else { return nil }
            return CustomerItem(vendorID: child.key, fields: fields)
        }
    }
}

extension CustomerItem {
    // Maps the legacy Vendor RTDB node onto CustomerItem.
    // Vendor-specific fields are packed into repurposed string slots:
    //   first    → vendor/company name (schema has no first/lastname)
    //   rate     → webpage/website
    //   adNo     → profession/trade
    //   callback → manager
    //   spouse   → assistant/secondary contact
    // creationDate is an ISO 8601 string in the Vendor node (epoch in others).
    init(vendorID: String, fields: [String: Any]) {
        func string(_ key: String) -> String {
            if let value = fields[key] as? String { return value }
            if let value = fields[key] as? NSNumber { return value.stringValue }
            return ""
        }
        func int(_ key: String) -> Int {
            if let value = fields[key] as? NSNumber { return value.intValue }
            return Int(string(key)) ?? 0
        }
        // Vendor creationDate is ISO 8601; lastUpdate is epoch. Try both formats.
        func date(_ key: String) -> Date? {
            if let n = fields[key] as? NSNumber {
                return Date(timeIntervalSince1970: n.doubleValue)
            }
            if let s = fields[key] as? String, !s.isEmpty {
                return ISO8601DateFormatter().date(from: s)
            }
            return nil
        }

        // zip is stored as Int in the RTDB export.
        let zip: String = {
            if let s = fields["zip"] as? String, !s.isEmpty { return s }
            if let n = fields["zip"] as? NSNumber { return n.stringValue }
            return ""
        }()

        let creationDate = date("creationDate") ?? Date()
        let lastUpdate = date("lastUpdate") ?? creationDate

        self.init(
            id: vendorID,
            isActive: int("active") == 1,
            first: string("vendor"),        // repurposed: vendor/company name
            lastname: "",
            street: string("address"),
            city: string("city"),
            state: string("state"),
            zip: zip,
            amount: 0,
            creationDate: creationDate,
            rate: string("assistant"),      // repurposed: assistant/secondary contact
            phone: string("phone"),
            comments: string("comments"),
            spouse: string("webpage"),      // repurposed: website
            email: string("email"),
            contractorIndex: 0,
            photo: string("photo"),
            lastUpdateDate: lastUpdate,
            startDate: creationDate,
            completionDate: creationDate,
            quantity: 0,
            salesIndex: 0,
            jobIndex: PickerDataModel.defaultPickProfession.firstIndex(of: string("profession")) ?? 0,
            productIndex: 0,
            category: CustomerItem.Category.vendor.rawValue,
            callback: string("manager"),    // repurposed: manager name
            adNo: ""
        )
    }
}
