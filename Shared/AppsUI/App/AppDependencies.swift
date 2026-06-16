//
//  AppDependencies.swift
//  TheLightUI
//

import CoreLocation
import Foundation

struct AppDependencies {
    let sessionService: SessionServicing
    let makeLoginService: () -> LoginServicing
    let makeAuthenticationService: () -> AuthenticationService
    let appBadgeManager: AppBadgeManaging
    let makeChatRepository: () -> ChatRepositoryProtocol
    let makeCustomerService: () -> CustomerServicing
    let makeCustomerFormService: () -> CustomerFormServicing
    let makeWeatherManager: () -> WeatherManaging
    let makeWeatherLocationProvider: () -> WeatherLocationProviding
    let makeLocationCaptureManager: () -> LocationCaptureManaging

    static let live = AppDependencies(
        sessionService: FirebaseSessionService(),
        makeLoginService: { FirebaseLoginService() },
        makeAuthenticationService: { AuthenticationService() },
        appBadgeManager: LiveAppBadgeManager(),
        makeChatRepository: { FirebaseChatRepository() },
        makeCustomerService: { FirebaseCustomerService() },
        makeCustomerFormService: { FirebaseCustomerFormService() },
        makeWeatherManager: { WeatherManager() },
        makeWeatherLocationProvider: { LocationWeatherManager() },
        makeLocationCaptureManager: { LocationCaptureManager() }
    )

    static let preview = AppDependencies(
        sessionService: PreviewSessionService(),
        makeLoginService: { PreviewLoginService() },
        makeAuthenticationService: { AuthenticationService() },
        appBadgeManager: PreviewAppBadgeManager(),
        makeChatRepository: { PreviewChatRepository() },
        makeCustomerService: { PreviewCustomerService() },
        makeCustomerFormService: { PreviewCustomerFormService() },
        makeWeatherManager: { PreviewWeatherManager() },
        makeWeatherLocationProvider: { PreviewWeatherLocationProvider() },
        makeLocationCaptureManager: { PreviewLocationCaptureManager() }
    )
}

struct PreviewSessionService: SessionServicing {
    var currentUserId: String? { "preview-user" }

    func signOut() throws { }
}

struct PreviewLoginService: LoginServicing {
    var currentUserId: String? { "preview-user" }

    func signIn(email: String, password: String) async throws -> String {
        "preview-user"
    }

    func createUser(email: String, password: String) async throws -> String {
        "preview-user"
    }

    func sendPasswordReset(email: String) async throws { }

    func sendEmailVerification() async throws { }

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

struct PreviewWeatherManager: WeatherManaging {
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> API.CurrentWeather.Response {
        API.CurrentWeather.Response(
            coord: .init(lon: longitude, lat: latitude),
            weather: [.init(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: .init(temp: 72, feels_like: 73, temp_min: 68, temp_max: 76, pressure: 1012, humidity: 48),
            name: "Preview City",
            wind: .init(speed: 7, deg: 180)
        )
    }
}

struct PreviewWeatherLocationProvider: WeatherLocationProviding {
    func requestLocation() async throws -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918)
    }
}

struct PreviewLocationCaptureManager: LocationCaptureManaging {
    func requestSingleLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        completion(CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918))
    }
}

private struct PreviewCustomerListener: CustomerListener {
    func remove() { }
}

private struct PreviewChatListener: ChatListener {
    func remove() { }
}
