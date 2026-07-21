//
//  CustomerUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

struct CustomerUI: View {
    @AppStorage("color") private var color: Int?
    @Environment(\.tabBarOverlap) private var tabBarOverlap
    @State private var viewModel: CustomerStore
    @State private var listViewModel: CustomerListViewModel
    @State private var transferViewModel: CustomerTransferViewModel
    @State private var pickerviewModel: PickerDataModel
    @Environment(\.openURL) private var openURL

    private let notificationManager = NotificationManager.shared
    private let formService: CustomerFormServicing
    private let appBadgeManager: AppBadgeManaging

    @State private var isAddingCustomer = false
    @State private var confirmMarkContacted = false
    @State private var pendingContactItem: CustomerItem? = nil

    @MainActor
    init(
        customerService: CustomerServicing = FirebaseCustomerService(),
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        appBadgeManager: AppBadgeManaging = LiveAppBadgeManager(),
        pickerviewModel: PickerDataModel = PickerDataModel(),
        categoryFilter: CustomerItem.Category? = nil
    ) {
        self.formService = formService
        self.appBadgeManager = appBadgeManager
        _viewModel = State(initialValue: CustomerStore(customerService: customerService))
        _listViewModel = State(initialValue: CustomerListViewModel(categoryFilter: categoryFilter))
        _transferViewModel = State(initialValue: CustomerTransferViewModel(formService: formService))
        _pickerviewModel = State(initialValue: pickerviewModel)
    }

    @MainActor
    init(
        viewModel: CustomerStore,
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        appBadgeManager: AppBadgeManaging = LiveAppBadgeManager(),
        pickerviewModel: PickerDataModel = PickerDataModel(),
        categoryFilter: CustomerItem.Category? = nil
    ) {
        self.formService = formService
        self.appBadgeManager = appBadgeManager
        _viewModel = State(initialValue: viewModel)
        _listViewModel = State(initialValue: CustomerListViewModel(categoryFilter: categoryFilter))
        _transferViewModel = State(initialValue: CustomerTransferViewModel(formService: formService))
        _pickerviewModel = State(initialValue: pickerviewModel)
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    // Title matches the main-menu route label the user tapped (Leads,
    // Customers, Vendors, Employee); unfiltered lists default to Customers.
    private var navigationTitle: String {
        listViewModel.categoryFilter?.listTitle ?? "Customers"
    }

    private func sanitizedPhone(_ raw: String) -> String? {
        let allowed = CharacterSet(charactersIn: "+0123456789 -().")
        guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        customerList
            .navigationDestination(for: CustomerItem.self) { item in
                LeadDetailUI(detail: item, formService: formService)
                    .environment(pickerviewModel)
                    .environment(viewModel)
                    .navigationBarBackButtonHidden(true)
            }
            .listStyle(.insetGrouped)
            .listRowSpacing(10)
            // The custom tab bar's safe-area inset doesn't reach Lists inside per-tab
            // NavigationStacks — re-apply it so the last row rests above the bar.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: tabBarOverlap)
                    .allowsHitTesting(false)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .tint(themeColor)
            .toolbar { toolbarContent }
            .searchable(text: $listViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always)) {
                Text("Balsamo").searchCompletion("Balsamo")
                Text("Rosch").searchCompletion("Rosch")
            }
            .refreshable {
                viewModel.fetchData()
            }
            .sheet(isPresented: $isAddingCustomer) {
                addCustomerForm
            }
            .onAppear {
                appBadgeManager.clearBadge()
            }
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
            // .data is included because fileExporter on some iOS versions saves without
            // a .json extension, which the system types as generic data (greying it out).
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
            .environment(viewModel)
    }

    private var customerList: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading Customers...")
            } else if viewModel.items.isEmpty {
                Text("No Customers")
            } else {
                activeOnlyToggle(count: listViewModel.displayedItems.count)
                customerRows(items: listViewModel.displayedItems)
            }
        }
    }

    private func activeOnlyToggle(count: Int) -> some View {
        Toggle(isOn: $listViewModel.isActiveOnly) {
            Text("\(count) Active Only")
        }
        .toggleStyle(.switch)
    }

    private func customerRows(items: [CustomerItem]) -> some View {
        ForEach(items) { item in
            // Value-based link: view-destination links trap with
            // AnyNavigationPath.Error.comparisonTypeMismatch on path-bound stacks.
            NavigationLink(value: item) {
                CustomerCellView(data: item, showsComments: !item.comments.isEmpty, color: color)
                    .equatable()
            }
            .contextMenu { rowContextMenu(for: item) }
            .swipeActions(edge: .leading) { leadingSwipeActions(for: item) }
            .swipeActions(edge: .trailing) { trailingSwipeActions(for: item) }
        }
        // No onMove: list order comes from the Firestore snapshot + selected sort;
        // a manual reorder targets wrong rows while filtered and is overwritten by the next snapshot.
        .onDelete { offsets in
            deleteItems(offsets.map { items[$0] })
        }
    }

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

    @ViewBuilder
    private func trailingSwipeActions(for item: CustomerItem) -> some View {
        Button(role: .destructive) {
            deleteItems([item])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

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
            Divider()
            Button {
                transferViewModel.importLegacyLeads(existingItems: viewModel.items)
            } label: {
                Label("Import Legacy Leads", systemImage: "person.crop.rectangle.stack")
            }
            .disabled(transferViewModel.isTransferring)
            Button {
                transferViewModel.importLegacyEmployees(existingItems: viewModel.items)
            } label: {
                Label("Import Legacy Employees", systemImage: "person.2.badge.gearshape")
            }
            .disabled(transferViewModel.isTransferring)
            Button {
                transferViewModel.importLegacyVendors(existingItems: viewModel.items)
            } label: {
                Label("Import Legacy Vendors", systemImage: "building.2")
            }
            .disabled(transferViewModel.isTransferring)
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var addCustomerForm: some View {
        // Pre-select the route's category so new entries created from a filtered list stay in it.
        var newCustomer = CustomerItem.emptyCustomer
        newCustomer.category = listViewModel.categoryFilter?.rawValue ?? ""
        return CustomerFormUI(
            detail: newCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: formService
        )
        .environment(viewModel)
        .environment(pickerviewModel)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            sortMenu

            Button(action: { isAddingCustomer = true }) {
                Label("New", systemImage: "plus")
            }
        }
    }

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

    private func deleteItems(_ items: [CustomerItem]) {
        viewModel.deleteItems(items)
    }
}

#Preview("Customers - Dark") {
    NavigationStack {
        CustomerUI(
            viewModel: CustomerStore(customerService: PreviewCustomerService()),
            formService: PreviewCustomerFormService(),
            appBadgeManager: PreviewAppBadgeManager()
        )
    }
    .preferredColorScheme(.dark)
}
