//
//  CustomerUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

// Customer list screen with search, filtering, sorting, and quick actions.

import SwiftUI

// CustomerUI
// Displays a list of customers with search, Active-only filter, and multiple sort modes.
// Provides navigation to detail, swipe/context actions, and a sheet to add new customers.
struct CustomerUI: View {
    // Persisted theme color choice.
    @AppStorage("color") private var color: Int?
    // State-backed models: data source, list presentation state, and picklist values.
    @State private var viewModel: CustomerData
    @State private var listViewModel: CustomerListViewModel
    @State private var pickerviewModel: PickerDataModel
    // Helper to open tel: and other URLs.
    @Environment(\.openURL) private var openURL
    
    // Singleton used to schedule/cancel local notifications.
    private let notificationManager = NotificationManager.shared
    // Injected services for customer forms and app badge state.
    private let formService: CustomerFormServicing
    private let appBadgeManager: AppBadgeManaging
    
    // UI state: add-sheet visibility.
    @State private var isAddingCustomer = false
    // Cache for displayed items to avoid recomputation every render.
    @State private var displayedItemsCache: [CustomerItem] = []
    // Confirmation dialog state for destructive/side-effectful actions.
    @State private var confirmMarkContacted = false
    @State private var pendingContactItem: CustomerItem? = nil
    // JSON import/export state.
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument: CustomerJSONDocument?
    @State private var transferMessage: String?
    @State private var isShowingTransferAlert = false
    
    // Primary initializer for production: creates its own data sources.
    @MainActor
    init(
        customerService: CustomerServicing = FirebaseCustomerService(),
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        appBadgeManager: AppBadgeManaging = LiveAppBadgeManager(),
        pickerviewModel: PickerDataModel = PickerDataModel()
    ) {
        self.formService = formService
        self.appBadgeManager = appBadgeManager
        _viewModel = State(initialValue: CustomerData(customerService: customerService))
        _listViewModel = State(initialValue: CustomerListViewModel())
        _pickerviewModel = State(initialValue: pickerviewModel)
    }

    // Convenience initializer for previews/tests: accepts an existing view model.
    @MainActor
    init(
        viewModel: CustomerData,
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        appBadgeManager: AppBadgeManaging = LiveAppBadgeManager(),
        pickerviewModel: PickerDataModel = PickerDataModel()
    ) {
        self.formService = formService
        self.appBadgeManager = appBadgeManager
        _viewModel = State(initialValue: viewModel)
        _listViewModel = State(initialValue: CustomerListViewModel())
        _pickerviewModel = State(initialValue: pickerviewModel)
    }
    
    // Derive theme color from AppStorage.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }
    
    // Basic phone validation/sanitization to ensure a safe tel: URL.
    private func sanitizedPhone(_ raw: String) -> String? {
        let allowed = CharacterSet(charactersIn: "+0123456789 -().")
        guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    // New helper method to update the displayed items cache.
    private func updateDisplayedItemsCache() {
        displayedItemsCache = listViewModel.displayedItems(from: viewModel.items)
    }

    var body: some View {
        // Main list content (loading/empty/states and rows).
        customerList
            .listStyle(.plain)
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.inline)
            .tint(themeColor)
            .toolbar { toolbarContent }
            // Built-in search field with sample completions.
            .searchable(text: $listViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always)) {
                Text("Balsamo").searchCompletion("Balsamo")
                Text("Rosch").searchCompletion("Rosch")
            }
            // Pull-to-refresh to re-fetch customer data.
            .refreshable {
                viewModel.fetchData()
            }
            // Present the add-customer form.
            .sheet(isPresented: $isAddingCustomer) {
                addCustomerForm
            }
            // Clear app badge when entering the list and initialize cache.
            .onAppear {
                appBadgeManager.clearBadge()
                updateDisplayedItemsCache()
            }
            .onChange(of: viewModel.items) {
                updateDisplayedItemsCache()
            }
            .onChange(of: listViewModel.searchText) {
                updateDisplayedItemsCache()
            }
            .onChange(of: listViewModel.isActiveOnly) {
                updateDisplayedItemsCache()
            }
            .onChange(of: listViewModel.selectedSort) {
                updateDisplayedItemsCache()
            }
            .confirmationDialog(
                "Mark as contacted?",
                isPresented: $confirmMarkContacted,
                titleVisibility: .visible
            ) {
                Button("Confirm", role: .destructive) {
                    // TODO: Ideally cancel notifications scoped to this customer only.
                    notificationManager.deleteNotifications()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove any pending reminders for \(pendingContactItem?.lastname ?? "this customer").")
            }
            // .data is included because fileExporter on some iOS versions saves the
            // file without a .json extension, which the system then types as generic
            // data and the picker would grey out.
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json, .plainText, .data]) { result in
                handleImport(result)
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "Customerswift.json"
            ) { result in
                if case .failure(let error) = result {
                    showTransferMessage("Export failed: \(error.localizedDescription)")
                }
            }
            .alert(transferMessage ?? "", isPresented: $isShowingTransferAlert) {
                Button("OK", role: .cancel) {}
            }
            // Inject shared models into subtree.
            .environment(viewModel)
    }

    // Top-level list container that handles loading/empty states and shows content.
    private var customerList: some View {
        let items = displayedItemsCache

        return List {
            // Loading state.
            if viewModel.isLoading {
                ProgressView("Loading Customers...")
            // Empty state.
            } else if viewModel.items.isEmpty {
                Text("No Customers")
            // Content state.
            } else {
                activeOnlyToggle(count: items.count)
                customerRows(items: items)
            }
        }
    }
    
    // Toggle to filter the list to only active customers.
    private func activeOnlyToggle(count: Int) -> some View {
        Toggle(isOn: $listViewModel.isActiveOnly) {
            Text("\(count) Active Only")
        }
        // Inherits the theme tint applied to the list via `.tint(themeColor)`.
        .toggleStyle(.switch)
    }
    
    // Rows: navigation to detail, context menu, and swipe actions.
    private func customerRows(items: [CustomerItem]) -> some View {
        ForEach(items) { item in
            // Navigate to detailed profile for the selected customer.
            NavigationLink {
                LeadDetailUI(detail: item, formService: formService)
                    .environment(pickerviewModel)
                    .navigationBarBackButtonHidden(true)
            } label: {
                CellView(data: item, showsComments: !item.comments.isEmpty, color: color)
                    .equatable()
            }
            .contextMenu { rowContextMenu(for: item) }
            // Long-press context menu.
            // Leading swipe: quick actions.
            .swipeActions(edge: .leading) { leadingSwipeActions(for: item) }
            // Trailing swipe: destructive delete.
            .swipeActions(edge: .trailing) { trailingSwipeActions(for: item) }
        }
        // Support delete via standard list editing.
        .onDelete { offsets in
            deleteItems(offsets.map { items[$0] })
        }
        // Allow manual reordering in edit mode.
        .onMove { offsets, newOffset in
            viewModel.items.move(fromOffsets: offsets, toOffset: newOffset)
        }
    }
    
    // Context menu actions for a row (call and schedule reminder).
    @ViewBuilder
    private func rowContextMenu(for item: CustomerItem) -> some View {
        Button {
            if let phone = sanitizedPhone(item.phone) {
                openURL.callPhoneNumber(phone)
            }
        } label: {
            Label("Call", systemImage: "phone")
        }
        Button {
            scheduleReminder(for: item)
        } label: {
            Label("Remind", systemImage: "bell")
        }
    }
    
    // Leading swipe actions: mark contacted (clears notifications) and schedule a reminder.
    @ViewBuilder
    private func leadingSwipeActions(for item: CustomerItem) -> some View {
        Button {
            pendingContactItem = item
            confirmMarkContacted = true
        } label: {
            Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
        }
        .tint(.green)

        Button {
            scheduleReminder(for: item)
        } label: {
            Label("Remind Me", systemImage: "bell")
        }
        .tint(.orange)
    }

    // Trailing swipe action: delete the item.
    @ViewBuilder
    private func trailingSwipeActions(for item: CustomerItem) -> some View {
        Button(role: .destructive) {
            deleteItems([item])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // Sort menu anchored in the toolbar with a Picker over all SortType cases,
    // plus JSON import/export actions.
    private var sortMenu: some View {
        Menu {
            Picker("Sorting options", selection: $listViewModel.selectedSort) {
                ForEach(CustomerListViewModel.SortType.allCases) { sort in
                    Label(sort.rawValue, systemImage: sort.systemImage)
                        .tag(sort)
                }
            }
            Divider()
            Button {
                isImporting = true
            } label: {
                Label("Import JSON", systemImage: "square.and.arrow.down")
            }
            Button {
                startExport()
            } label: {
                Label("Export JSON", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.items.isEmpty)
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    // Sheet content for adding a new customer using the shared form.
    private var addCustomerForm: some View {
        FormUI(
            detail: .emptyCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: formService
        )
        .environment(viewModel)
        .environment(pickerviewModel)
    }

    // Toolbar: edit mode toggle, add new customer, and sort menu.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Enable list editing (delete/reorder).
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }

        // Actions: open sort menu and add new customer (trailing edge).
        ToolbarItemGroup(placement: .topBarTrailing) {
            sortMenu

            Button(action: { isAddingCustomer = true }) {
                Label("New", systemImage: "plus")
            }
        }
    }

    // Schedule a repeating 8:30 AM reminder to contact the customer.
    private func scheduleReminder(for item: CustomerItem) {
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 30
        notificationManager.scheduleNotification(
            title: "Contact \(item.lastname)",
            body: "Email \(item.email)",
            categoryIdentifier: "reminder",
            dateComponents: dateComponents,
            repeats: true
        )
    }

    // Delegate deletion to the view model.
    private func deleteItems(_ items: [CustomerItem]) {
        viewModel.deleteItems(items)
    }

    // MARK: - JSON Import/Export

    // Encode the current customer list and present the file exporter.
    private func startExport() {
        do {
            exportDocument = CustomerJSONDocument(data: try CustomerJSONTransfer.exportData(for: viewModel.items))
            isExporting = true
        } catch {
            showTransferMessage("Export failed: \(error.localizedDescription)")
        }
    }

    // Read the picked file and hand its decoded records to the importer.
    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            importRecords(try CustomerJSONTransfer.decodeRecords(from: data))
        } catch {
            showTransferMessage("Import failed: \(error.localizedDescription)")
        }
    }

    // Upserts imported records into Firestore. Records that keep their exported
    // document id overwrite the matching document, so re-importing a backup
    // restores edits instead of duplicating customers. The snapshot listener
    // refreshes the list automatically once the writes land.
    private func importRecords(_ records: [CustomerJSONRecord]) {
        let existingIDs = Set(viewModel.items.map(\.id))
        Task {
            var inserted = 0
            var updated = 0
            do {
                for record in records {
                    let item = record.customerItem
                    let payload = CustomerFormPayload(
                        customer: item,
                        amount: item.amount,
                        quantity: item.quantity,
                        rate: item.rate,
                        creationDate: item.creationDate,
                        startDate: item.startDate,
                        completionDate: item.completionDate,
                        lastUpdateDate: item.lastUpdateDate,
                        userId: formService.currentUserId
                    )
                    if item.id.isEmpty {
                        _ = try await formService.addCustomer(payload)
                        inserted += 1
                    } else {
                        try await formService.updateCustomer(id: item.id, payload: payload)
                        if existingIDs.contains(item.id) {
                            updated += 1
                        } else {
                            inserted += 1
                        }
                    }
                }
                showTransferMessage(importMessage(inserted: inserted, updated: updated))
            } catch {
                showTransferMessage("Import failed after \(inserted + updated) of \(records.count) customers: \(error.localizedDescription)")
            }
        }
    }

    private func importMessage(inserted: Int, updated: Int) -> String {
        switch (inserted, updated) {
        case (0, 0):
            return "No customers found in this file."
        case (_, 0):
            return "Imported \(inserted) customer\(inserted == 1 ? "" : "s")."
        case (0, _):
            return "Updated \(updated) existing customer\(updated == 1 ? "" : "s")."
        default:
            return "Imported \(inserted) new and updated \(updated) existing customer\(inserted + updated == 1 ? "" : "s")."
        }
    }

    private func showTransferMessage(_ message: String) {
        transferMessage = message
        isShowingTransferAlert = true
    }
}

// MARK: - Customer Cell

// Layout constants for sizes used in the cell.
struct CellView: View, Equatable {
    fileprivate enum Layout {
        static let avatarSize: CGFloat = 60
        static let actionIconSize: CGFloat = 20
        static let summaryWidth: CGFloat = 90
        static let summaryHeight: CGFloat = 25
        static let textMinimumScaleFactor = 0.5
    }

    // Customer data to render.
    let data: CustomerItem
    // Whether to enable the comments action.
    let showsComments: Bool
    // Persisted theme color choice passed down from the parent list.
    let color: Int?
    
    // Cell-local theme color convenience.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }
    
    // Row layout: avatar, summary, spacer, and amount/date summary.
    var body: some View {
        HStack(alignment: .top) {
            avatar
            customerSummary
            Spacer()
            amountSummary
        }
    }

    // Monogram avatar built from the customer's initials.
    private var avatar: some View {
        InitialsAvatarView(firstName: data.first, lastName: data.lastname, size: Layout.avatarSize)
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .padding(.top, 5)
    }

    // Name, address, and row-level actions.
    private var customerSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.lastname)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .customerCellScaledText()
                .padding(.top, 3)
                .accessibilityLabel(Text("Customer name \(data.lastname)"))

            Text(data.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .customerCellSingleLineText()
                .accessibilityLabel(Text("Address \(data.address)"))

            rowActions
        }
        .padding(.leading, 10)
    }

    // Inline action icons (message-like and like).
    private var rowActions: some View {
        HStack(spacing: 20) {
            // Only enabled when there are comments to show.
            Button(action: {}) {
                actionIcon("text.bubble.fill")
            }
            .disabled(!showsComments)

            Button(action: {}) {
                actionIcon("hand.thumbsup.fill")
            }
        }
        .buttonStyle(.plain)
    }

    // Right-aligned date and amount summary.
    private var amountSummary: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(data.formattedCreationDate)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .font(.caption2)
                .foregroundStyle(themeColor)
                .customerCellScaledText()
                .padding(.top, 3)
                .accessibilityLabel(Text("Created on \(data.formattedCreationDate)"))

            Text(data.formattedAmount)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .customerCellSingleLineText()
                .foregroundStyle(.primary)
                .font(.headline)
                .accessibilityLabel(Text("Amount \(data.formattedAmount)"))
        }
    }

    // Helper to render a consistent action icon.
    private func actionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: Layout.actionIconSize, height: Layout.actionIconSize)
            .foregroundStyle(themeColor)
    }
}

private extension View {
    func customerCellScaledText() -> some View {
        minimumScaleFactor(CellView.Layout.textMinimumScaleFactor)
    }

    func customerCellSingleLineText() -> some View {
        lineLimit(1)
            .customerCellScaledText()
    }
}

// Preview: customers list in dark mode.
#Preview("Customers - Dark") {
    NavigationStack {
        CustomerUI(
            viewModel: CustomerData(customerService: PreviewCustomerService()),
            formService: PreviewCustomerFormService(),
            appBadgeManager: PreviewAppBadgeManager()
        )
    }
    .preferredColorScheme(.dark)
}

