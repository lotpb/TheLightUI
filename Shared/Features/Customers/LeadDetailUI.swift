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

// Layout constants for spacing and corner radius
private enum LeadDetailLayout {
    static let containerSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 10
    static let rowHorizontalPadding: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 12
    static let containerCornerRadius: CGFloat = 14
    static let maxWidthForIpad: CGFloat = 700
}

// A reusable list where each row renders as its own rounded card with spacing
// between rows, like Reminders, matching the spaced list style used app-wide.
// Rows are identified by their element's stable id so state and animations survive updates.
private struct RoundedContainerList<RowData: Identifiable, RowContent: View>: View {
    let rows: [RowData]
    let rowContent: (RowData) -> RowContent

    init(_ rows: [RowData], @ViewBuilder rowContent: @escaping (RowData) -> RowContent) {
        self.rows = rows
        self.rowContent = rowContent
    }

    var body: some View {
        VStack(spacing: LeadDetailLayout.rowSpacing) {
            ForEach(rows) { data in
                rowContent(data)
                    .padding(.horizontal, LeadDetailLayout.rowHorizontalPadding)
                    .padding(.vertical, LeadDetailLayout.rowVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LeadDetailLayout.containerCornerRadius, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.2))
                    )
            }
        }
    }
}

// LeadDetailUI
// Displays a customer's detail profile with a header, a list of fields, comments, and an action toolbar.
// Coordinates system sheets (edit form, email, message, add contact, add calendar event)
// and integrates with Contacts, EventKit, and location sharing via a Coordinator.

struct LeadDetailUI: View {
    // Shared picklist data used to resolve indices into human-readable values.
    @Environment(PickerDataModel.self) private var pickerviewModel
    // Live customer list — used to sync detail after the edit form saves to Firestore.
    @Environment(CustomerStore.self) private var customerStore
    // User-configurable settings stored in AppStorage (theme color and default calendar settings).
    @AppStorage("color") private var color: Int?
    @AppStorage("activeColor") private var activeColor: Int?
    @AppStorage(SettingsUI.eventKey) private var calendarEventTitle: String = ""
    @AppStorage(SettingsUI.durationKey) private var calendarEventDuration: String = ""
    // Environment utilities for dismissing and opening URLs.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // Service used to load/save customer forms (DI for testability).
    private let formService: CustomerFormServicing
    // Abstraction that provides current location for sharing.
    private let locationProvider: WeatherLocationProviding

    // Mutable customer model being displayed/edited.
    @State private var detail: CustomerItem
    // Orchestrates sheets, alerts, and side-effects for this screen.
    @State private var coordinator: LeadDetailCoordinator
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
        self._coordinator = State(initialValue: LeadDetailCoordinator(formService: formService, locationProvider: locationProvider))
    }

    // Derive the active theme color from persisted setting.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    private var isLead: Bool {
        CustomerItem.Category.lead.matches(detail.category)
    }

    private var isEmployee: Bool {
        CustomerItem.Category.employee.matches(detail.category)
    }

    private var isVendor: Bool {
        CustomerItem.Category.vendor.matches(detail.category)
    }

    // Flatten the domain model into label/value rows for display.
    // Employees and vendors get dedicated field sets with their own labels.
    // For leads, contractor and completion date are hidden (not applicable to the lead lifecycle).
    private var detailFields: [CustomerDetailField] {
        if isEmployee { return employeeDetailFields }
        if isVendor { return vendorDetailFields }

        var fields = [
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
            CustomerDetailField(name: detail.formattedStartDate, label: isLead ? CustomerLabels.aptDate : CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.callback),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.adNo),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
        if isLead {
            fields.removeAll { $0.label == CustomerLabels.contractor || $0.label == CustomerLabels.complete }
        } else {
            fields.removeAll { $0.label == CustomerLabels.callback }
        }
        return fields
    }

    // Employee records store their specific data in repurposed CustomerItem fields;
    // this list uses the correct labels for each slot.
    private var employeeDetailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.socialSecurity),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: detail.adNo, label: CustomerLabels.department),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.middle),
            CustomerDetailField(name: detail.formattedStartDate, label: CustomerLabels.startDate),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }

    // Vendor records store their specific data in repurposed CustomerItem fields;
    // first holds the company/vendor name (schema has no first/lastname).
    private var vendorDetailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.first, label: CustomerLabels.vendorName),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: detail.category, label: CustomerLabels.vendorCategory),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.website),
            CustomerDetailField(name: detail.lastname, label: CustomerLabels.profession),
            CustomerDetailField(name: detail.callback, label: CustomerLabels.manager),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }

    // Default SMS body, personalized if a first name is available.
    private var defaultMessageBody: String {
        let firstName = trimmed(detail.first)
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
        // (which writes to Firestore) are reflected immediately without reopening.
        .onChange(of: customerStore.items) { _, items in
            if let updated = items.first(where: { $0.id == detail.id }) {
                detail = updated
            }
        }
        // Apply theme color to foreground and accent (tint).
        .foregroundStyle(themeColor)
        .tint(themeColor)
        .background(Color(.systemGroupedBackground))
        // Keep content comfortably narrow on large screens.
        .frame(maxWidth: LeadDetailLayout.maxWidthForIpad)
    }

    // Reusable list of labeled customer fields with separators and rounded container.
    private var detailFieldList: some View {
        RoundedContainerList(detailFields) { customer in
            LeadDetailFieldRow(formData: customer)
        }
        .padding(.horizontal)
    }

    // Toolbar: close, actions menu, and edit entry point.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Leading: dismiss button.
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { dismiss() }) {
                Label("Close", systemImage: "xmark.circle")
            }
            .accessibilityLabel("Close")
        }

        // Trailing: overflow action menu.
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                actionMenuButtons
            } label: {
                Label("Action", systemImage: "ellipsis.circle")
            }
        }

        // Trailing: Edit button opens the form sheet.
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
            CustomerFormUI(
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

    // Safely look up a value by index in a picklist.
    private func pickerValue(_ values: [String], at index: Int) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }

    // MARK: - String helpers
    private func trimmed(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func nonEmpty(_ parts: [String], separator: String = ", ") -> String {
        parts.map { trimmed($0) }.filter { !$0.isEmpty }.joined(separator: separator)
    }

    // Build a CNMutableContact from the current customer fields.
    private func makeContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = trimmed(detail.first)
        contact.familyName = trimmed(detail.lastname)

        // Phone number (if provided).
        let phone = trimmed(detail.phone)
        if !phone.isEmpty {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
        }

        // Email address (if provided).
        let email = trimmed(detail.email)
        if !email.isEmpty {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
        }

        // Postal address (if any address fields are present).
        if !fullAddress.isEmpty {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = trimmed(detail.street)
            postalAddress.city = trimmed(detail.city)
            postalAddress.state = trimmed(detail.state)
            postalAddress.postalCode = trimmed(detail.zip)
            contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postalAddress)]
        }

        // Related contact: spouse (if provided).
        let spouse = trimmed(detail.spouse)
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
        let configuredTitle = trimmed(calendarEventTitle)
        if !configuredTitle.isEmpty { return configuredTitle }

        let customerName = nonEmpty([detail.first, detail.lastname], separator: " ")
        return customerName.isEmpty ? "Appointment" : "Appt. with \(customerName)"
    }

    // Duration for the event in seconds, parsed from minutes (default 60).
    private var calendarEventDurationSeconds: TimeInterval {
        let minutes = Double(trimmed(calendarEventDuration)) ?? 60
        return max(minutes, 1) * 60
    }

    // Full mailing address composed from non-empty parts.
    private var fullAddress: String {
        nonEmpty([detail.street, detail.city, detail.state, detail.zip])
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

    // HTML-formatted representation of the customer record for printing.
    private var printableHTML: String {
        let name = nonEmpty([detail.first, detail.lastname], separator: " ")
        let address = fullAddress

        var fieldRows = ""
        for field in detailFields {
            let value = field.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, value != "none" else { continue }
            let escaped = value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            fieldRows += """
            <tr>
              <td class="label">\(field.label)</td>
              <td class="value">\(escaped)</td>
            </tr>
            """
        }

        let commentsSection: String
        if !detail.comments.isEmpty {
            let escaped = detail.comments
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            commentsSection = """
            <div class="comments-section">
              <div class="comments-title">Comments</div>
              <div class="comments-body">\(escaped)</div>
            </div>
            """
        } else {
            commentsSection = ""
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; margin: 40px; color: #1c1c1e; }
          .header { border-bottom: 2px solid #007aff; padding-bottom: 14px; margin-bottom: 24px; }
          .name { font-size: 26px; font-weight: 700; color: #007aff; }
          .address { font-size: 14px; color: #6e6e73; margin-top: 4px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          td { padding: 8px 12px; font-size: 14px; vertical-align: top; }
          .label { font-weight: 600; color: #3a3a3c; width: 38%; }
          .value { color: #1c1c1e; }
          .comments-section { background: #f2f2f7; border-radius: 10px; padding: 14px 16px; }
          .comments-title { font-weight: 700; font-size: 14px; color: #3a3a3c; margin-bottom: 6px; }
          .comments-body { font-size: 14px; color: #1c1c1e; line-height: 1.5; }
          .footer { margin-top: 32px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style>
        </head>
        <body>
          <div class="header">
            <div class="name">\(name.isEmpty ? "Customer Profile" : name)</div>
            \(address.isEmpty ? "" : "<div class=\"address\">\(address)</div>")
          </div>
          <table>\(fieldRows)</table>
          \(commentsSection)
          <div class="footer">Printed from The Light &bull; \(Date().formatted(date: .long, time: .omitted))</div>
        </body>
        </html>
        """
    }

    private func printDetail() {
        #if canImport(UIKit)
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = nonEmpty([detail.first, detail.lastname], separator: " ")
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: printableHTML)
        controller.printFormatter = formatter
        controller.present(animated: true)
        #endif
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
