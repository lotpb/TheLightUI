//
//  CompanySession.swift
//  TheLightUI
//
// Caches the current user's companyId from Firebase custom claims in
// UserDefaults so Firestore writes can stamp it synchronously without
// an async token fetch on every write.

import Foundation
import FirebaseAuth

enum CompanySession {
    private static let key = "companyIdClaim"

    /// The cached companyId, or nil if not yet fetched / user is signed out.
    static var companyId: String? {
        UserDefaults.standard.string(forKey: key)
    }

    /// Fetches the latest ID-token claims and caches companyId.
    /// Call this after every sign-in and on app startup when already authenticated.
    @discardableResult
    static func refresh() async -> String? {
        guard let user = Auth.auth().currentUser else {
            clear()
            return nil
        }
        guard let result = try? await user.getIDTokenResult(forcingRefresh: false) else { return companyId }
        if let id = result.claims["companyId"] as? String, !id.isEmpty {
            UserDefaults.standard.set(id, forKey: key)
            return id
        }
        return companyId
    }

    /// Clears the cached value on sign-out.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
