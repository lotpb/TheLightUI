//
//  AppDependencies.swift
//  TheLightUI
//

import Foundation

struct AppDependencies {
    let sessionService: SessionServicing
    let makeLoginService: () -> LoginServicing
    let makeAuthenticationService: () -> AuthenticationService
    let appBadgeManager: AppBadgeManaging
    let makeChatRepository: () -> ChatRepositoryProtocol
    let makeCustomerService: () -> CustomerServicing
    let makeCustomerFormService: () -> CustomerFormServicing

    static let live = AppDependencies(
        sessionService: FirebaseSessionService(),
        makeLoginService: { FirebaseLoginService() },
        makeAuthenticationService: { AuthenticationService() },
        appBadgeManager: LiveAppBadgeManager(),
        makeChatRepository: { FirebaseChatRepository() },
        makeCustomerService: { FirebaseCustomerService() },
        makeCustomerFormService: { FirebaseCustomerFormService() }
    )

    static let preview = AppDependencies(
        sessionService: PreviewSessionService(),
        makeLoginService: { PreviewLoginService() },
        makeAuthenticationService: { AuthenticationService() },
        appBadgeManager: PreviewAppBadgeManager(),
        makeChatRepository: { PreviewChatRepository() },
        makeCustomerService: { PreviewCustomerService() },
        makeCustomerFormService: { PreviewCustomerFormService() }
    )
}

struct PreviewSessionService: SessionServicing {
    var currentUserId: String? { "preview-user" }

    func signOut() throws { }
}

struct PreviewLoginService: LoginServicing {
    func signIn(email: String, password: String) async throws -> String {
        "preview-user"
    }

    func createUser(email: String, password: String) async throws -> String {
        "preview-user"
    }

    func fetchUserSettings(userId: String) async throws -> LoginUserSettings {
        LoginUserSettings(
            firstName: "Preview",
            lastName: "User",
            email: "preview@example.com",
            phoneNumber: "(555) 010-0000"
        )
    }

    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> URL {
        URL(string: "https://example.com/profile.jpg") ?? URL(fileURLWithPath: "/dev/null")
    }

    func storeUserInformation(
        email: String,
        userId: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        profileImageURL: URL
    ) async throws { }
}

struct PreviewCustomerService: CustomerServicing {
    func listenForCustomers(onChange: @escaping (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        onChange(.success([]))
        return PreviewCustomerListener()
    }

    func deleteCustomer(id: String) async throws { }
}

struct PreviewCustomerFormService: CustomerFormServicing {
    var currentUserId: String? { "preview-user" }

    func addCustomer(_ payload: CustomerFormPayload) async throws -> String {
        "preview-customer"
    }

    func updateCustomer(id: String, payload: CustomerFormPayload) async throws { }
}

struct PreviewChatRepository: ChatRepositoryProtocol {
    var currentUserId: String? { "preview-user" }

    func signOut() throws { }

    func fetchCurrentUser() async throws -> UserModel {
        UserModel(
            uid: "preview-user",
            email: "preview@example.com",
            profileImageUrl: ""
        )
    }

    func fetchAvailableUsers() async throws -> [UserModel] {
        []
    }

    func listenForRecentMessages(
        userId: String,
        onChange: @escaping ([RecentMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        onChange([])
        return PreviewChatListener()
    }

    func listenForMessages(
        fromId: String,
        toId: String,
        onMessages: @escaping ([ChatMessage]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ChatListener {
        onMessages([])
        return PreviewChatListener()
    }

    func sendTextMessage(_ text: String, to chatUser: UserModel) async throws { }

    func sendImageMessage(_ imageData: Data, to chatUser: UserModel) async throws { }
}

private struct PreviewCustomerListener: CustomerListener {
    func remove() { }
}

private struct PreviewChatListener: ChatListener {
    func remove() { }
}
