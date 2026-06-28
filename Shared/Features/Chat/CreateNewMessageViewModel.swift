//
//  CreateNewMessageViewModel.swift
//  TheLightUI
//

import Foundation
import Observation

@MainActor
@Observable
final class CreateNewMessageViewModel {
    var users = [UserModel]()
    var errorMessage = ""

    @ObservationIgnored private let repository: ChatRepositoryProtocol
    @ObservationIgnored private var fetchUsersTask: Task<Void, Never>?

    init(repository: ChatRepositoryProtocol = FirebaseChatRepository()) {
        self.repository = repository
        refreshUsers()
    }

    deinit {
        fetchUsersTask?.cancel()
    }

    func refreshUsers() {
        fetchUsersTask?.cancel()
        fetchUsersTask = Task { [weak self] in
            await self?.fetchAllUsers()
        }
    }

    func fetchAllUsers() async {
        do {
            let availableUsers = try await repository.fetchAvailableUsers()
            guard !Task.isCancelled else { return }
            users = availableUsers
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Failed to fetch users: \(error.localizedDescription)"
        }
    }
}
