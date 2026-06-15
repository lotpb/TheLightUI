import Foundation
import CoreLocation
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

@MainActor
final class LeadDetailCoordinator: ObservableObject {
    // Inputs
    private let formService: CustomerFormServicing
    private let locationProvider: WeatherLocationProviding

    // Exposed state to drive UI
    @Published var activeSheet: LeadDetailCoordinator.ActiveSheet?
    @Published var messageBodyOverride: String?
    @Published var isRequestingLocationShare: Bool = false
    @Published var locationAlertMessage: String?
    @Published var showFullscreen: Bool = false
    @Published var showPopover: Bool = false

    enum ActiveSheet: Identifiable {
        case edit
        case email
        case message
        case contact
        case calendarEvent

        var id: String {
            switch self {
            case .edit: return "edit"
            case .email: return "email"
            case .message: return "message"
            case .contact: return "contact"
            case .calendarEvent: return "calendarEvent"
            }
        }
    }

    init(formService: CustomerFormServicing, locationProvider: WeatherLocationProviding) {
        self.formService = formService
        self.locationProvider = locationProvider
    }

    var canSendMessages: Bool {
        #if canImport(MessageUI)
        MFMessageComposeViewController.canSendText()
        #else
        false
        #endif
    }

    func presentEdit() {
        activeSheet = .edit
    }

    func presentEmail() {
        activeSheet = .email
    }

    func presentMessage() {
        activeSheet = .message
    }

    func presentContact() {
        activeSheet = .contact
    }

    func presentCalendarEvent() {
        activeSheet = .calendarEvent
    }

    func dismissSheet() {
        activeSheet = nil
        messageBodyOverride = nil
    }

    func shareMyLocation() {
        guard canSendMessages else {
            activeSheet = .message
            return
        }
        guard !isRequestingLocationShare else { return }

        // Mark as requesting on the main actor
        isRequestingLocationShare = true

        // Use a regular Task to inherit @MainActor from the class context
        Task { [weak self] in
            guard let self else { return }
            do {
                let coordinate = try await self.locationProvider.requestLocation()
                // We are already on the main actor because LeadDetailCoordinator is @MainActor
                self.presentLocationMessage(coordinate)
                self.isRequestingLocationShare = false
            } catch {
                // Back on the main actor; safe to publish changes
                self.locationAlertMessage = Self.locationUnavailableMessage()
                self.isRequestingLocationShare = false
            }
        }
    }

    @MainActor func presentLocationMessage(_ coordinate: CLLocationCoordinate2D) {
        messageBodyOverride = Self.shareLocationMessageBody(for: coordinate)
        activeSheet = .message
    }

    static func shareLocationMessageBody(for coordinate: CLLocationCoordinate2D) -> String {
        "Here is my current location: https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)"
    }

    static func locationUnavailableMessage() -> String {
        "Turn on Location Services for this app in Settings > Privacy & Security > Location Services to share your current location."
    }
}

