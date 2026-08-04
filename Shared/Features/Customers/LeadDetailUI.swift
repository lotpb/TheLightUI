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
    // Live customer list — used to sync detail after the edit form saves to Firestore.
    @Environment(CustomerStore.self) private var customerStore
    // User-configurable settings stored in AppStorage.
    @AppStorage(SettingsUI.color) private var color: Int?
    @AppStorage(SettingsUI.activeColorKey) private var activeColor: Int?
    // Internal so calendar extension can read these settings.
    @AppStorage(SettingsUI.eventKey) var calendarEventTitle: String = ""
    @AppStorage(SettingsUI.durationKey) var calendarEventDuration: String = ""
    // Environment utilities for dismissing and opening URLs.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.tabBarOverlap) private var tabBarOverlap

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
    @State private var ssnUnlocked = false
    @State private var showSSNPasswordPrompt = false
    @State private var ssnPasswordEntry = ""
    @State private var adminPassword: String = ""

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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: tabBarOverlap)
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
        .alert("Admin Access Required", isPresented: $showSSNPasswordPrompt) {
            SecureField("Password", text: $ssnPasswordEntry)
            Button("Unlock") {
                if ssnPasswordEntry == adminPassword {
                    ssnUnlocked = true
                }
                ssnPasswordEntry = ""
            }
            Button("Cancel", role: .cancel) { ssnPasswordEntry = "" }
        } message: {
            Text("Enter administrator password to view Social Security Number.")
        }
        // Mirror the customer's active state into AppStorage to drive theme accents.
        .onAppear(perform: syncActiveColor)
        .onAppear {
            adminPassword = SecureSettingsStore.loadString(forKey: SettingsUI.adminPasswordKey, defaultValue: "admin")
        }
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
    // Customer category splits Phone and Email into a dedicated Contact section.
    @ViewBuilder
    private var detailFieldList: some View {
        if isCustomer {
            customerSectionedFieldList
        } else if isLead {
            leadSectionedFieldList
        } else if isVendor {
            vendorSectionedFieldList
        } else if isEmployee {
            employeeSectionedFieldList
        } else {
            RoundedContainerList(detailFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            .padding(.horizontal)
        }
    }

    private var customerSectionedFieldList: some View {
        let contactLabels: Set<String> = [CustomerLabels.phone, CustomerLabels.email, CustomerLabels.callback]
        let jobInfoLabels: Set<String> = [CustomerLabels.salesman, CustomerLabels.job, CustomerLabels.product, CustomerLabels.contractor, CustomerLabels.quantity, CustomerLabels.adNo]
        let dateLabels: Set<String> = ["Sale Date", CustomerLabels.startDate, CustomerLabels.complete, CustomerLabels.lastUpdated]
        let personalLabels: Set<String> = [CustomerLabels.spouse, CustomerLabels.photo]
        let addressLabels: Set<String> = ["Street", "City", "State", "Zip"]
        let allSectionLabels = contactLabels.union(jobInfoLabels).union(dateLabels).union(personalLabels).union(addressLabels)
        let mainFields = detailFields.filter { !allSectionLabels.contains($0.label) }
        let contactFields = detailFields.filter { contactLabels.contains($0.label) }
        let jobInfoFields = detailFields.filter { jobInfoLabels.contains($0.label) }
        let dateFields = detailFields.filter { dateLabels.contains($0.label) }
        let personalFields = detailFields.filter { personalLabels.contains($0.label) }
        let addressFields = detailFields.filter { addressLabels.contains($0.label) }
        return VStack(spacing: LeadDetailLayout.containerSpacing) {
            RoundedContainerList(mainFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            addressSectionHeader
            RoundedContainerList(addressFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            contactSectionHeader
            RoundedContainerList(contactFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            jobInfoSectionHeader
            RoundedContainerList(jobInfoFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            datesSectionHeader
            RoundedContainerList(dateFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            personalSectionHeader
            RoundedContainerList(personalFields) { field in
                LeadDetailFieldRow(formData: field)
            }
        }
        .padding(.horizontal)
    }

    private var leadSectionedFieldList: some View {
        let addressLabels: Set<String> = ["Street", "City", "State", "Zip"]
        let contactLabels: Set<String> = [CustomerLabels.phone, CustomerLabels.email]
        let jobInfoLabels: Set<String> = [CustomerLabels.salesman, CustomerLabels.job, CustomerLabels.product, CustomerLabels.contractor, CustomerLabels.quantity, CustomerLabels.callback, CustomerLabels.adNo]
        let dateLabels: Set<String> = ["Sale Date", CustomerLabels.aptDate, CustomerLabels.complete, CustomerLabels.lastUpdated]
        let personalLabels: Set<String> = [CustomerLabels.spouse, CustomerLabels.photo]
        let allSectionLabels = addressLabels.union(contactLabels).union(jobInfoLabels).union(dateLabels).union(personalLabels)
        let mainFields = detailFields.filter { !allSectionLabels.contains($0.label) }
        let addressFields = detailFields.filter { addressLabels.contains($0.label) }
        let contactFields = detailFields.filter { contactLabels.contains($0.label) }
        let jobInfoFields = detailFields.filter { jobInfoLabels.contains($0.label) }
        let dateFields = detailFields.filter { dateLabels.contains($0.label) }
        let personalFields = detailFields.filter { personalLabels.contains($0.label) }
        return VStack(spacing: LeadDetailLayout.containerSpacing) {
            RoundedContainerList(mainFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            contactSectionHeader
            RoundedContainerList(contactFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            addressSectionHeader
            RoundedContainerList(addressFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            jobInfoSectionHeader
            RoundedContainerList(jobInfoFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            datesSectionHeader
            RoundedContainerList(dateFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            personalSectionHeader
            RoundedContainerList(personalFields) { field in
                LeadDetailFieldRow(formData: field)
            }
        }
        .padding(.horizontal)
    }

    private var vendorSectionedFieldList: some View {
        let addressLabels: Set<String> = ["Street", "City", "State", "Zip"]
        let jobInfoLabels: Set<String> = [CustomerLabels.profession, CustomerLabels.manager, CustomerLabels.callback]
        let contactLabels: Set<String> = [CustomerLabels.phone, CustomerLabels.email, CustomerLabels.website, CustomerLabels.photo]
        let dateLabels: Set<String> = ["Date Added", CustomerLabels.lastUpdated]
        let allSectionLabels = addressLabels.union(jobInfoLabels).union(contactLabels).union(dateLabels)
        let mainFields = detailFields.filter { !allSectionLabels.contains($0.label) }
        let addressFields = detailFields.filter { addressLabels.contains($0.label) }
        let jobInfoFields = detailFields.filter { jobInfoLabels.contains($0.label) }
        let contactFields = detailFields.filter { contactLabels.contains($0.label) }
        let dateFields = detailFields.filter { dateLabels.contains($0.label) }
        return VStack(spacing: LeadDetailLayout.containerSpacing) {
            RoundedContainerList(mainFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            contactSectionHeader
            RoundedContainerList(contactFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            addressSectionHeader
            RoundedContainerList(addressFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            jobInfoSectionHeader
            RoundedContainerList(jobInfoFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            datesSectionHeader
            RoundedContainerList(dateFields) { field in
                LeadDetailFieldRow(formData: field)
            }
        }
        .padding(.horizontal)
    }

    private var employeeSectionedFieldList: some View {
        let addressLabels: Set<String> = ["Street", "City", "State", "Zip"]
        let employeeInfoLabels: Set<String> = [CustomerLabels.phone, CustomerLabels.email, CustomerLabels.department, CustomerLabels.callback, CustomerLabels.photo]
        let dateLabels: Set<String> = ["Date Added", CustomerLabels.startDate, CustomerLabels.endDate, CustomerLabels.birthDate, CustomerLabels.lastUpdated]
        let personalLabels: Set<String> = [CustomerLabels.socialSecurity, CustomerLabels.driverLicense, CustomerLabels.spouse]
        let allSectionLabels = addressLabels.union(employeeInfoLabels).union(dateLabels).union(personalLabels)
        let mainFields = detailFields.filter { !allSectionLabels.contains($0.label) }
        let addressFields = detailFields.filter { addressLabels.contains($0.label) }
        let employeeInfoFields = detailFields.filter { employeeInfoLabels.contains($0.label) }
        let dateFields = detailFields.filter { dateLabels.contains($0.label) }
        let personalFields = detailFields.filter { personalLabels.contains($0.label) }
        return VStack(spacing: LeadDetailLayout.containerSpacing) {
            RoundedContainerList(mainFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            addressSectionHeader
            RoundedContainerList(addressFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            employeeInfoSectionHeader
            RoundedContainerList(employeeInfoFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            datesSectionHeader
            RoundedContainerList(dateFields) { field in
                LeadDetailFieldRow(formData: field)
            }
            personalSectionHeader
            RoundedContainerList(personalFields) { field in
                if field.label == CustomerLabels.socialSecurity {
                    ssnDetailRow(field: field)
                } else {
                    LeadDetailFieldRow(formData: field)
                }
            }
        }
        .padding(.horizontal)
    }

    private var addressSectionHeader: some View {
        HStack {
            Text("Address")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 0)
    }

    private var personalSectionHeader: some View {
        HStack {
            Text("Personal")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var datesSectionHeader: some View {
        HStack {
            Text("Dates")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var jobInfoSectionHeader: some View {
        HStack {
            Text("Job Info")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var contactSectionHeader: some View {
        HStack {
            Text("Contact")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var employeeInfoSectionHeader: some View {
        HStack {
            Text("Employee Info")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(themeColor)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func ssnDetailRow(field: CustomerDetailField) -> some View {
        HStack(spacing: 12) {
            Text(field.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Spacer()
            if ssnUnlocked {
                Text(field.name)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                HStack(spacing: 8) {
                    if !field.name.isEmpty {
                        Text("•••-••-••••")
                            .font(.body)
                            .foregroundStyle(Color.secondary)
                    }
                    Button {
                        ssnPasswordEntry = ""
                        showSSNPasswordPrompt = true
                    } label: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    // Normalizes the vendor's web page string into a URL, prefixing https:// if needed.
    private var websiteURL: URL? {
        guard isVendor, !detail.spouse.isEmpty else { return nil }
        let raw = detail.spouse
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        return URL(string: "https://\(raw)")
    }

    // Action menu items for contact/calendar/email/message/phone and location sharing.
    @ViewBuilder
    private var actionMenuButtons: some View {
        if let url = websiteURL {
            Button { openURL(url) } label: {
                Label("Open Website", systemImage: "safari")
            }
        }
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
            contractor: "",
            photo: "none",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 5,
            salesman: "",
            job: "",
            product: ""
        ))
        .environment(CustomerStore())
        .environment(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
