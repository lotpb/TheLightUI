// Lead detail screen showing profile, fields, actions, and utilities (contacts, email, messages, calendar).

//
//  LeadDetailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import CoreLocation
import EventKit
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

// Layout constants for spacing and corner radius.
// Internal so RoundedContainerList (in its own file) can reference them.
enum LeadDetailLayout {
    static let containerSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 10
    static let rowHorizontalPadding: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 12
    static let containerCornerRadius: CGFloat = 14
    static let maxWidthForIpad: CGFloat = 700
}

// LeadDetailUI
// Displays a customer's detail profile with a header, a list of fields, comments, and an action toolbar.
// Coordinates system sheets (edit form, email, message, add contact, add calendar event)
// and integrates with Contacts, EventKit, and location sharing via a Coordinator.

struct LeadDetailUI: View {
    // Shared picklist data — internal so extension files can build field rows.
    @Environment(PickerDataModel.self) var pickerviewModel
    // Live customer list — used to sync detail after the edit form saves to Firestore.
    @Environment(CustomerStore.self) private var customerStore
    // User-configurable settings stored in AppStorage.
    @AppStorage("color") private var color: Int?
    @AppStorage("activeColor") private var activeColor: Int?
    // Internal so calendar extension can read these settings.
    @AppStorage(SettingsUI.eventKey) var calendarEventTitle: String = ""
    @AppStorage(SettingsUI.durationKey) var calendarEventDuration: String = ""
    // Environment utilities for dismissing and opening URLs.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // Service used to load/save customer forms (DI for testability).
    private let formService: CustomerFormServicing
    // Abstraction that provides current location for sharing.
    private let locationProvider: WeatherLocationProviding

    // Internal so extension files (field data, contact, calendar, print) can read/bind to it.
    @State var detail: CustomerItem
    // Orchestrates sheets, alerts, and side-effects for this screen.
    @State private var coordinator: LeadDetailCoordinator
    // Internal so calendar extension can create EKEvents.
    @State var calendarEventStore = EKEventStore()

    init(
        detail: CustomerItem,
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        locationProvider: WeatherLocationProviding = LocationWeatherManager()
    ) {
        self._detail = State(initialValue: detail)
        self.formService = formService
        self.locationProvider = locationProvider
        self._coordinator = State(initialValue: LeadDetailCoordinator(formService: formService, locationProvider: locationProvider))
    }

    // Derive the active theme color from persisted setting.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    var body: some View {
        ZStack {
            // Background color to match grouped system appearance.
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Scrollable content with header, fields, and comments.
            ScrollView(.vertical) {
                VStack(spacing: LeadDetailLayout.containerSpacing) {
                    // Photo/name header with fullscreen photo support.
                    LeadDetailHeaderView(detail: $detail, showFullscreen: $coordinator.showFullscreen)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Key/value field list.
                    detailFieldList

                    // Notes/comments section.
                    LeadDetailCommentsView(detail: $detail, showPopover: $coordinator.showPopover, accentColor: themeColor)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $coordinator.activeSheet, content: sheetContent)
        .alert("Location Unavailable", isPresented: locationAlertIsPresented) {
            Button("OK", role: .cancel) { coordinator.locationAlertMessage = nil }
        } message: {
            Text(coordinator.locationAlertMessage ?? "")
        }
        // Mirror the customer's active state into AppStorage to drive theme accents.
        .onAppear(perform: syncActiveColor)
        .onChange(of: detail.isActive) {
            syncActiveColor()
        }
        // Keep detail in sync with the store so edits saved via the form sheet
        // are reflected immediately without reopening.
        .onChange(of: customerStore.items) { _, items in
            if let updated = items.first(where: { $0.id == detail.id }) {
                detail = updated
            }
        }
        .foregroundStyle(themeColor)
        .tint(themeColor)
        .background(Color(.systemGroupedBackground))
        // Keep content comfortably narrow on large screens.
        .frame(maxWidth: LeadDetailLayout.maxWidthForIpad)
    }

    // Reusable list of labeled customer fields with rounded card containers.
    private var detailFieldList: some View {
        RoundedContainerList(detailFields) { customer in
            LeadDetailFieldRow(formData: customer)
        }
        .padding(.horizontal)
    }

    // Toolbar: close, actions menu, and edit entry point.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { dismiss() }) {
                Label("Close", systemImage: "xmark.circle")
            }
            .accessibilityLabel("Close")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                actionMenuButtons
            } label: {
                Label("Action", systemImage: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { coordinator.presentEdit() }) {
                Text("Edit").fontWeight(.semibold)
            }
            .accessibilityLabel("Edit")
        }
    }

    // Action menu items for contact/calendar/email/message/phone and location sharing.
    @ViewBuilder
    private var actionMenuButtons: some View {
        Button { coordinator.presentContact() } label: {
            Label("Add to Contacts", systemImage: "person.crop.circle.badge.plus")
        }
        Button { coordinator.presentCalendarEvent() } label: {
            Label("Add Calendar Event", systemImage: "calendar.badge.plus")
        }
        // Asynchronously request and share a one-time location link.
        Button(action: { coordinator.shareMyLocation() }) {
            HStack {
                Label("Share My Location", systemImage: "location")
                if coordinator.isRequestingLocationShare {
                    Spacer(minLength: 8)
                    ProgressView()
                }
            }
        }
        .disabled(coordinator.isRequestingLocationShare)
        Button { openURL.callPhoneNumber(detail.phone) } label: {
            Label("Call Phone", systemImage: "phone")
        }
        Button { coordinator.presentEmail() } label: {
            Label("Send Email", systemImage: "envelope")
        }
        if coordinator.canSendMessages {
            Button { coordinator.presentMessage() } label: {
                Label("Send Message", systemImage: "message")
            }
        }
        Button { printDetail() } label: {
            Label("Print", systemImage: "printer")
        }
    }

    // Conditionally render the correct sheet content for the active action.
    @ViewBuilder
    private func sheetContent(_ sheet: LeadDetailCoordinator.ActiveSheet) -> some View {
        switch sheet {
        // Edit customer in-place using shared form.
        case .edit:
            let editForm = CustomerFormUI(
                detail: detail,
                createDate: detail.creationDate,
                startDate: detail.startDate,
                completeDate: detail.completionDate,
                mode: .edit,
                formService: formService
            )
            editForm.presentationSizing(.page)
        // Compose email with parsed recipients.
        case .email:
            let recipients = parsedEmailRecipients(from: detail.email)
            MailView(
                content: .theLightSupport(recipients: recipients),
                onResult: { _ in coordinator.dismissSheet() }
            )
        case .message:
            // Only present message composer on devices that support it.
            #if canImport(MessageUI)
            if MFMessageComposeViewController.canSendText() {
                let recipients = parsedRecipients(from: detail.phone)
                let body = coordinator.messageBodyOverride ?? defaultMessageBody
                MessageComposeView(recipients: recipients.isEmpty ? nil : recipients, body: body) { _ in
                    coordinator.dismissSheet()
                }
            } else {
                unavailableMessageView(text: "Messaging is not available on this device.")
            }
            #else
            unavailableMessageView(text: "Messaging framework not available.")
            #endif
        case .contact:
            // Pre-populate a CNMutableContact for saving.
            #if canImport(ContactsUI)
            ContactAddView(
                contact: makeContact(),
                onComplete: { coordinator.dismissSheet() }
            )
            #else
            unavailableMessageView(text: "Contacts are not available on this device.")
            #endif
        case .calendarEvent:
            // Create an EKEvent with sensible defaults and allow editing.
            #if canImport(EventKitUI)
            CalendarEventEditView(
                event: makeCalendarEvent(),
                eventStore: calendarEventStore,
                onComplete: { _ in coordinator.dismissSheet() }
            )
            #else
            unavailableMessageView(text: "Calendar events are not available on this device.")
            #endif
        }
    }

    // Helper binding to show/hide the location failure alert.
    private var locationAlertIsPresented: Binding<Bool> {
        Binding(
            get: { coordinator.locationAlertMessage != nil },
            set: { if !$0 { coordinator.locationAlertMessage = nil } }
        )
    }

    // Generic placeholder view used when a capability isn't available.
    private func unavailableMessageView(text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.headline)
            Button("Close") { coordinator.dismissSheet() }
                .accessibilityLabel("Close")
        }
        .padding()
    }

    // Mirror the customer's active state into AppStorage to drive theme accents.
    private func syncActiveColor() {
        activeColor = detail.isActive ? 1 : 0
    }
}

// Preview with sample data for design-time visualization.
#Preview("Lead Detail - Dark") {
    NavigationStack {
        LeadDetailUI(detail: CustomerItem(
            id: "8899999",
            isActive: true,
            first: "Peter",
            lastname: "Balsamo",
            street: "5121 Lakefront Blvd Apt D",
            city: "Delray Beach",
            state: "FL",
            zip: "33484",
            amount: 5000,
            creationDate: Date(),
            rate: "",
            phone: "516-241-4786",
            comments: "Hello",
            spouse: "Janet",
            email: "eunitedws@icloud.com",
            contractorIndex: 5,
            photo: "none",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 5,
            salesIndex: 1,
            jobIndex: 1,
            productIndex: 1
        ))
        .environment(CustomerStore())
        .environment(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
