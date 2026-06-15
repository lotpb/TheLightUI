// Lead detail screen showing profile, fields, actions, and utilities (contacts, email, messages, calendar).

//
//  LeadDetailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import Contacts
import CoreLocation
import EventKit
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

// LeadDetailUI
// Displays a customer's detail profile with a header, a list of fields, comments, and an action toolbar.
// Coordinates system sheets (edit form, email, message, add contact, add calendar event)
// and integrates with Contacts, EventKit, and location sharing via a Coordinator.

struct LeadDetailUI: View {
    // Shared picklist data used to resolve indices into human-readable values.
    @EnvironmentObject private var pickerviewModel: PickerDataModel
    // User-configurable settings stored in AppStorage (theme color and default calendar settings).
    @AppStorage("color") private var color: Int?
    @AppStorage("activeColor") private var activeColor: Int?
    @AppStorage(SettingsUI.eventKey) private var calendarEventTitle: String = ""
    @AppStorage(SettingsUI.durationKey) private var calendarEventDuration: String = ""
    // Environment utilities for dismissing and opening URLs.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // Constrain max width for a centered, readable layout on iPad.
    private let maxWidthForIpad: CGFloat = 700
    // Service used to load/save customer forms (DI for testability).
    private let formService: CustomerFormServicing
    // Abstraction that provides current location for sharing.
    private let locationProvider: WeatherLocationProviding

    // Mutable customer model being displayed/edited.
    @State var detail: CustomerItem
    // Orchestrates sheets, alerts, and side-effects for this screen.
    @StateObject private var coordinator: LeadDetailCoordinator
    // EventKit store used when creating/editing calendar events.
    @State private var calendarEventStore = EKEventStore()

    init(
        detail: CustomerItem,
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        locationProvider: WeatherLocationProviding = LocationWeatherManager()
    ) {
        // Inject dependencies and initialize the coordinator with the same services.
        self._detail = State(initialValue: detail)
        self.formService = formService
        self.locationProvider = locationProvider
        self._coordinator = StateObject(wrappedValue: LeadDetailCoordinator(formService: formService, locationProvider: locationProvider))
    }

    // Derive the active theme color from persisted setting.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    // Flatten the domain model into label/value rows for display.
    private var detailFields: [CustomerDetailField] {
        [
            // Map indices (contractor, salesman, job, product) to strings using pickerviewModel.
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickContractor, at: detail.contractorIndex), label: CustomerLabels.contractor),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.spouse),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickSalesman, at: detail.salesIndex), label: CustomerLabels.salesman),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickJob, at: detail.jobIndex), label: CustomerLabels.job),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickProduct, at: detail.productIndex), label: CustomerLabels.product),
            CustomerDetailField(name: "\(detail.quantity)", label: CustomerLabels.quantity),
            CustomerDetailField(name: detail.formattedStartDate, label: CustomerLabels.start),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: "\(detail.id)", label: CustomerLabels.photo)
        ]
    }

    // Default SMS body, personalized if a first name is available.
    private var defaultMessageBody: String {
        let firstName = detail.first.trimmingCharacters(in: .whitespacesAndNewlines)
        return firstName.isEmpty
            ? "Hi, following up on your inquiry."
            : "Hi \(firstName), following up on your inquiry."
    }

    var body: some View {
        ZStack {
            // Background color to match grouped system appearance.
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Scrollable content with header, fields, and comments.
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
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
        // Present different system sheets based on coordinator state.
        .alert("Location Unavailable", isPresented: locationAlertIsPresented) {
            // Alert surfaced when location can't be obtained for sharing.
            Button("OK", role: .cancel) { coordinator.locationAlertMessage = nil }
        } message: {
            Text(coordinator.locationAlertMessage ?? "")
        }
        // Apply theme color to foreground and accent (tint).
        .foregroundColor(themeColor)
        .tint(themeColor)
        .background(Color(.systemGroupedBackground))
        // Keep content comfortably narrow on large screens.
        .frame(maxWidth: maxWidthForIpad)
    }

    // Reusable list of labeled customer fields with separators and rounded container.
    private var detailFieldList: some View {
        let fields = detailFields

        return LazyVStack(spacing: 0) {
            // Enumerate with indices so we can draw dividers between rows.
            ForEach(Array(fields.enumerated()), id: \.offset) { index, customer in
                LeadDetailFieldRow(formData: customer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .overlay(alignment: .bottom) {
                        if index < fields.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .padding(.horizontal)
        .onAppear(perform: syncActiveColor)
        // Sync the isActive flag to AppStorage so other screens can react.
        .onChange(of: detail.isActive) { _ in
            // Keep AppStorage in sync when the record's active status changes.
            syncActiveColor()
        }
    }

    // Toolbar: close, actions menu, and edit entry point.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Leading: dismiss button.
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Label("Close", systemImage: "xmark.circle")
            }
            .accessibilityLabel("Close")
        }

        // Trailing: overflow action menu.
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                actionMenuButtons
            } label: {
                Label("Action", systemImage: "ellipsis.circle")
            }
        }

        // Trailing: Edit button opens the form sheet.
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { coordinator.presentEdit() }) {
                Text("Edit").fontWeight(.semibold)
            }
            .accessibilityLabel("Edit")
        }
    }

    // Action menu items for contact/calendar/email/message/phone and location sharing.
    @ViewBuilder
    private var actionMenuButtons: some View {
        Button("Add to Contacts") { coordinator.presentContact() }
        Button("Add Calendar Event") { coordinator.presentCalendarEvent() }
        // Asynchronously request and share a one-time location link.
        Button(action: { coordinator.shareMyLocation() }) {
            HStack {
                Text("Share My Location")
                if coordinator.isRequestingLocationShare {
                    Spacer(minLength: 8)
                    ProgressView()
                }
            }
        }
        .disabled(coordinator.isRequestingLocationShare)
        Button("Call Phone") { openURL.callPhoneNumber(detail.phone) }
        Button("Send Email") { coordinator.presentEmail() }
        if coordinator.canSendMessages {
            Button("Send Message") { coordinator.presentMessage() }
        }
        //Button("Add to Customer") { }
        //Button("$ pay") { }
        //Button("Web Page") { }
    }

    // Conditionally render the correct sheet content for the active action.
    @ViewBuilder
    private func sheetContent(_ sheet: LeadDetailCoordinator.ActiveSheet) -> some View {
        switch sheet {
        // Edit customer in-place using shared form.
        case .edit:
            FormUI(
                detail: detail,
                createDate: detail.creationDate,
                startDate: detail.startDate,
                completeDate: detail.completionDate,
                mode: .edit,
                formService: formService
            )
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
                MessageComposeView(recipients: recipients.isEmpty ? nil : recipients, body: coordinator.messageBodyOverride ?? defaultMessageBody) { _ in
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
        }
        .padding()
    }

    // Safely look up a value by index in a picklist.
    private func pickerValue(_ values: [String], at index: Int) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }

    // Build a CNMutableContact from the current customer fields.
    private func makeContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = detail.first.trimmingCharacters(in: .whitespacesAndNewlines)
        contact.familyName = detail.lastname.trimmingCharacters(in: .whitespacesAndNewlines)

        // Phone number (if provided).
        let phone = detail.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if !phone.isEmpty {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
        }

        // Email address (if provided).
        let email = detail.email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
        }

        // Postal address (if any address fields are present).
        if !fullAddress.isEmpty {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = detail.street.trimmingCharacters(in: .whitespacesAndNewlines)
            postalAddress.city = detail.city.trimmingCharacters(in: .whitespacesAndNewlines)
            postalAddress.state = detail.state.trimmingCharacters(in: .whitespacesAndNewlines)
            postalAddress.postalCode = detail.zip.trimmingCharacters(in: .whitespacesAndNewlines)
            contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postalAddress)]
        }

        // Related contact: spouse (if provided).
        let spouse = detail.spouse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !spouse.isEmpty {
            contact.contactRelations = [CNLabeledValue(label: CNLabelContactRelationSpouse, value: CNContactRelation(name: spouse))]
        }

        return contact
    }

    // Build a calendar event using defaults from settings and customer details.
    private func makeCalendarEvent() -> EKEvent {
        let event = EKEvent(eventStore: calendarEventStore)
        event.calendar = calendarEventStore.defaultCalendarForNewEvents
        event.title = calendarEventSummary
        event.startDate = detail.startDate
        event.endDate = detail.startDate.addingTimeInterval(calendarEventDurationSeconds)
        event.location = fullAddress
        event.notes = calendarEventNotes
        return event
    }

    // Title for the calendar event; uses AppStorage override or falls back to customer name.
    private var calendarEventSummary: String {
        let configuredTitle = calendarEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !configuredTitle.isEmpty { return configuredTitle }

        let customerName = [detail.first, detail.lastname]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return customerName.isEmpty ? "Appointment" : "Appt. with \(customerName)"
    }

    // Duration for the event in seconds, parsed from minutes (default 60).
    private var calendarEventDurationSeconds: TimeInterval {
        let minutes = Double(calendarEventDuration.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 60
        return max(minutes, 1) * 60
    }

    // Full mailing address composed from non-empty parts.
    private var fullAddress: String {
        [detail.street, detail.city, detail.state, detail.zip]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    // Notes to include in the event (phone, email, comments).
    private var calendarEventNotes: String {
        [
            detail.phone.isEmpty ? nil : "Phone: \(detail.phone)",
            detail.email.isEmpty ? nil : "Email: \(detail.email)",
            detail.comments.isEmpty ? nil : "Comments: \(detail.comments)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    // Normalize a phone string into a single digits-only recipient array for SMS.
    private func parsedRecipients(from raw: String) -> [String] {
        let digitsOnly = PhoneNumber(raw: raw).digitsOnly
        return digitsOnly.isEmpty ? [] : [digitsOnly]
    }

    // Split a raw email string on common separators and keep valid addresses.
    private func parsedEmailRecipients(from raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",; ")
        return raw
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.contains("@") }
    }

    // Mirror the customer's active state into AppStorage to drive theme accents.
    private func syncActiveColor() {
        activeColor = detail.isActive ? 1 : 0
    }
}

// Preview with sample data for design-time visualization.
struct LeadDetailUI_Previews: PreviewProvider {
    static var previews: some View {
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
            rate: "5",
            phone: "516-241-4786",
            comments: "Hello",
            spouse: "Janet",
            email: "eunitedws@icloud.com.com",
            contractorIndex: 5,
            photo: "none",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 5,
            salesIndex: 1,
            jobIndex: 1,
            productIndex: 1,
            status: .edit,
            formController: "Customer"
        ))
        .environmentObject(CustomerData())
        .environmentObject(PickerDataModel())
        .preferredColorScheme(.dark)
    }
}
