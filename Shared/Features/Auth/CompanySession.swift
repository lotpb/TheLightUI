//
//  CompanySession.swift
//  TheLightUI
//
// Caches the current user's companyId from Firebase custom claims in
// UserDefaults so Firestore writes can stamp it synchronously without
// an async token fetch on every write.

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum CompanySession {
    private static let key = "companyIdClaim"

    /// The cached companyId, or nil if not yet fetched / user is signed out.
    static var companyId: String? {
        UserDefaults.standard.string(forKey: key)
    }

    /// Fetches the latest ID-token claims and caches companyId.
    /// Call this after every sign-in and on app startup when already authenticated.
    @discardableResult
    static func refresh(forcingRefresh: Bool = false) async -> String? {
        guard let user = Auth.auth().currentUser else {
            clear()
            return nil
        }
        guard let result = try? await user.getIDTokenResult(forcingRefresh: forcingRefresh) else { return companyId }
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

    // MARK: - Live claim refresh

    // Mirrors the web app's claimRefreshSignals listener: watches the
    // caller's own signal doc (written server-side by Cloud Functions after
    // a custom-claims change, e.g. being invited to a company) and force-
    // refreshes the cached companyId within ~1 second, instead of requiring
    // the user to relaunch the app or sign out/in to see their new company's
    // data. `claimSignalListener` is @MainActor-isolated so it never needs
    // `nonisolated(unsafe)`.
    @MainActor
    private static var claimSignalListener: ListenerRegistration?

    /// Starts watching claimRefreshSignals/{uid} for the current user.
    /// Call after every sign-in and on app startup when already authenticated.
    @MainActor
    static func startWatchingClaimRefresh() {
        stopWatchingClaimRefresh()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        claimSignalListener = Firestore.firestore()
            .collection("claimRefreshSignals")
            .document(uid)
            .addSnapshotListener { _, _ in
                Task { await CompanySession.refresh(forcingRefresh: true) }
            }
    }

    /// Stops watching for claim-refresh signals. Call on sign-out.
    @MainActor
    static func stopWatchingClaimRefresh() {
        claimSignalListener?.remove()
        claimSignalListener = nil
    }
}
