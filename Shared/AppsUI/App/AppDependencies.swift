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

    nonisolated(unsafe) static let live = AppDependencies(
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

    nonisolated(unsafe) static let preview = AppDependencies(
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

    func validateRegistration(firstName: String, lastName: String, email: String, phoneNumber: String) throws { }

    func storeUserInformation(
        email: String,
        userId: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        profileImageURL: URL
    ) async throws { }

    func updateUserLocation(userId: String, latitude: Double, longitude: Double) async throws { }
}

struct PreviewCustomerService: CustomerServicing {
    func listenForCustomers(onChange: @escaping (Result<[CustomerItem], Error>) -> Void) -> CustomerListener {
        onChange(.success(CustomerItem.previewSamples))
        return PreviewCustomerListener()
    }

    func deleteCustomer(id: String) async throws { }
}

// Sample customers shown by PreviewCustomerService so previews render a
// populated list without touching Firebase (which is never configured in
// previews).
extension CustomerItem {
    static let previewSamples: [CustomerItem] = [
        .previewSample(
            id: "preview-1",
            first: "Peter",
            lastname: "Balsamo",
            street: "213 Higbie Lane",
            city: "West Islip",
            amount: 12500,
            daysAgo: 3,
            comments: "Called about siding estimate."
        ),
        .previewSample(
            id: "preview-2",
            first: "Karen",
            lastname: "Rosch",
            street: "48 Ocean Ave",
            city: "Babylon",
            amount: 8400,
            daysAgo: 12
        ),
        .previewSample(
            id: "preview-3",
            first: "John",
            lastname: "Pellegrino",
            street: "9 Maple Ct",
            city: "Bay Shore",
            amount: 21750,
            daysAgo: 30,
            comments: "Wants Andersen windows, follow up in fall.",
            isActive: false
        )
    ]

    private static func previewSample(
        id: String,
        first: String,
        lastname: String,
        street: String,
        city: String,
        amount: Int,
        daysAgo: Int,
        comments: String = "",
        isActive: Bool = true
    ) -> CustomerItem {
        var item = CustomerItem.emptyCustomer
        item.id = id
        item.isActive = isActive
        item.first = first
        item.lastname = lastname
        item.street = street
        item.city = city
        item.state = "NY"
        item.zip = "11704"
        item.amount = amount
        item.creationDate = Date().addingTimeInterval(-Double(daysAgo) * 86400)
        item.rate = "5"
        item.phone = "(631) 555-0123"
        item.comments = comments
        item.email = "\(first.lowercased())@example.com"
        item.quantity = 1
        return item
    }
}

struct PreviewCustomerFormService: CustomerFormServicing {
    var currentUserId: String? { "preview-user" }

    func addCustomer(_ payload: CustomerFormPayload) async throws -> String {
        "preview-customer"
    }

    func updateCustomer(id: String, payload: CustomerFormPayload) async throws { }

    func upsertCustomersBatch(_ entries: [(id: String, payload: CustomerFormPayload)]) async throws { }
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
    func requestSingleLocation() async -> CLLocationCoordinate2D? {
        CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918)
    }
}

private struct PreviewCustomerListener: CustomerListener {
    func remove() { }
}

private struct PreviewChatListener: ChatListener {
    func remove() { }
}
