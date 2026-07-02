//
//  SessionViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

protocol SessionServicing: Sendable {
    var currentUserId: String? { get }
    func signOut() throws
}

struct FirebaseSessionService: SessionServicing {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    var currentUserId: String? {
        manager.auth.currentUser?.uid
    }

    func signOut() throws {
        try manager.auth.signOut()
        manager.currentUser = nil
    }
}

@MainActor
@Observable
final class SessionViewModel {
    private(set) var isAuthenticated: Bool
    var isLoginPresented: Bool
    var errorMessage = ""

    @ObservationIgnored private let sessionService: SessionServicing

    init(sessionService: SessionServicing = FirebaseSessionService()) {
        self.sessionService = sessionService
        let hasCurrentUser = sessionService.currentUserId != nil
        self.isAuthenticated = hasCurrentUser
        self.isLoginPresented = !hasCurrentUser
    }

    func handleLoginCompleted() {
        isAuthenticated = true
        isLoginPresented = false
        errorMessage = ""
    }

    func signOut() {
        do {
            try sessionService.signOut()
            isAuthenticated = false
            isLoginPresented = true
            errorMessage = ""
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
