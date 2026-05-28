//
//  AppDependencies.swift
//  TheLightUI
//

import Foundation

struct AppDependencies {
    let sessionService: SessionServicing
    let loginService: LoginServicing
    let authenticationService: AuthenticationService
    let makeChatRepository: () -> ChatRepositoryProtocol
    let makeCustomerService: () -> CustomerServicing
    let makeCustomerFormService: () -> CustomerFormServicing

    static let live = AppDependencies(
        sessionService: FirebaseSessionService(),
        loginService: FirebaseLoginService(),
        authenticationService: AuthenticationService(),
        makeChatRepository: { FirebaseChatRepository() },
        makeCustomerService: { FirebaseCustomerService() },
        makeCustomerFormService: { FirebaseCustomerFormService() }
    )
}
