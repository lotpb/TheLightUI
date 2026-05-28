//
//  CreateNewMessageViewModel.swift
//  TheLightUI
//

import Foundation

@MainActor
final class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [UserModel]()
    @Published var errorMessage = ""

    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol = FirebaseChatRepository()) {
        self.repository = repository
        Task {
            await fetchAllUsers()
        }
    }

    func fetchAllUsers() async {
        do {
            users = try await repository.fetchAvailableUsers()
        } catch {
            errorMessage = "Failed to fetch users: \(error.localizedDescription)"
        }
    }
}
