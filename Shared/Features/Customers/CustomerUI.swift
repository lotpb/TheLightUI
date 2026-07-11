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
    // State-backed models: data source, list presentation state, JSON transfer,
    // and picklist values.
    @State private var viewModel: CustomerData
    @State private var listViewModel: CustomerListViewModel
    @State private var transferViewModel: CustomerTransferViewModel
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
    // Confirmation dialog state for destructive/side-effectful actions.
    @State private var confirmMarkContacted = false
    @State private var pendingContactItem: CustomerItem? = nil

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
        _transferViewModel = State(initialValue: CustomerTransferViewModel(formService: formService))
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
        _transferViewModel = State(initialValue: CustomerTransferViewModel(formService: formService))
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
            // Clear app badge when entering the list.
            .onAppear {
                appBadgeManager.clearBadge()
            }
            // Keep the list view model's source collection in sync with the
            // data source; filtering/sorting recomputes inside the model.
            .onChange(of: viewModel.items, initial: true) {
                listViewModel.allItems = viewModel.items
            }
            .confirmationDialog(
                "Mark as contacted?",
                isPresented: $confirmMarkContacted,
                titleVisibility: .visible,
                presenting: pendingContactItem
            ) { _ in
                Button("Confirm", role: .destructive) {
                    // TODO: Ideally cancel notifications scoped to this customer only.
                    notificationManager.deleteNotifications()
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("This will remove any pending reminders for \(item.lastname).")
            }
            // .data is included because fileExporter on some iOS versions saves the
            // file without a .json extension, which the system then types as generic
            // data and the picker would grey out.
            .fileImporter(isPresented: $transferViewModel.isImporting, allowedContentTypes: [.json, .plainText, .data]) { result in
                transferViewModel.handleImport(result, existingItems: viewModel.items)
            }
            .fileExporter(
                isPresented: $transferViewModel.isExporting,
                document: transferViewModel.exportDocument,
                contentType: .json,
                defaultFilename: "Customerswift.json"
            ) { result in
                transferViewModel.finishExport(result)
            }
            .alert(transferViewModel.alertMessage ?? "", isPresented: $transferViewModel.isShowingAlert) {
                Button("OK", role: .cancel) {}
            }
            // Inject shared models into subtree.
            .environment(viewModel)
    }

    // Top-level list container that handles loading/empty states and shows content.
    private var customerList: some View {
        List {
            // Loading state.
            if viewModel.isLoading {
                ProgressView("Loading Customers...")
            // Empty state.
            } else if viewModel.items.isEmpty {
                Text("No Customers")
            // Content state.
            } else {
                activeOnlyToggle(count: listViewModel.displayedItems.count)
                customerRows(items: listViewModel.displayedItems)
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
                CustomerCellView(data: item, showsComments: !item.comments.isEmpty, color: color)
                    .equatable()
            }
            // Long-press context menu.
            .contextMenu { rowContextMenu(for: item) }
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
                transferViewModel.isImporting = true
            } label: {
                Label("Import JSON", systemImage: "square.and.arrow.down")
            }
            Button {
                transferViewModel.startExport(items: viewModel.items)
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
