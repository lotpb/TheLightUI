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
                activeOnlyToggle
                let sections = listViewModel.displayedSections
                if sections.isEmpty {
                    customerRows(items: listViewModel.displayedItems)
                } else {
                    ForEach(sections, id: \.header) { section in
                        Section(section.header) {
                            customerRows(items: section.items)
                        }
                    }
                }
            }
        }
    }

    private var activeOnlyToggle: some View {
        Toggle(isOn: $listViewModel.isActiveOnly) {
            Text(listViewModel.isActiveOnly
                 ? "\(listViewModel.displayedItems.count) Active"
                 : "\(listViewModel.totalCount) \(listViewModel.categoryFilter?.listTitle ?? "Total")")
                .foregroundStyle(themeColor)
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
        Button {
            toggleActive(item)
        } label: {
            Label(item.isActive ? "Inactive" : "Active", systemImage: item.isActive ? "minus.circle" : "checkmark.circle")
        }
        .tint(item.isActive ? .gray : .blue)

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
                printList()
            } label: {
                Label("Print", systemImage: "printer")
            }
            .disabled(listViewModel.displayedItems.isEmpty)

        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func printList() {
        #if canImport(UIKit)
        let title = navigationTitle
        let items = listViewModel.displayedItems
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
        }
        var rows = ""
        for item in items {
            let name = [item.first, item.lastname].filter { !$0.isEmpty }.joined(separator: " ")
            let amount = item.amount == 0 ? "" : "$\(item.amount)"
            rows += "<tr><td>\(escape(name))</td><td>\(escape(item.phone))</td><td>\(escape(item.city))</td><td>\(amount)</td></tr>\n"
        }
        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; margin: 40px; color: #1c1c1e; }
          h1 { font-size: 22px; font-weight: 700; color: #007aff; border-bottom: 2px solid #007aff; padding-bottom: 10px; margin-bottom: 20px; }
          table { width: 100%; border-collapse: collapse; }
          th { text-align: left; padding: 8px 10px; font-size: 13px; color: #6e6e73; border-bottom: 1px solid #c7c7cc; }
          td { padding: 8px 10px; font-size: 13px; vertical-align: top; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          .footer { margin-top: 28px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style></head><body>
          <h1>\(escape(title))</h1>
          <table><tr><th>Name</th><th>Phone</th><th>City</th><th>Amount</th></tr>\(rows)</table>
          <div class="footer">Printed from The Light &bull; \(Date().formatted(date: .long, time: .omitted)) &bull; \(items.count) record\(items.count == 1 ? "" : "s")</div>
        </body></html>
        """
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = title
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        controller.present(animated: true)
        #endif
    }

    @ViewBuilder
    private var addCustomerForm: some View {
        // Pre-select the route's category so new entries created from a filtered list stay in it.
        let newCustomer: CustomerItem = {
            var c = CustomerItem.emptyCustomer
            c.category = listViewModel.categoryFilter?.rawValue ?? ""
            return c
        }()
        let form = CustomerFormUI(
            detail: newCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: formService
        )
        .environment(viewModel)
        .environment(pickerviewModel)
        form.presentationSizing(.page)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
                .tint(themeColor)
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            sortMenu
                .tint(themeColor)

            Button(action: { isAddingCustomer = true }) {
                Label("New", systemImage: "plus")
            }
            .tint(themeColor)
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

    private func toggleActive(_ item: CustomerItem) {
        var modified = item
        modified.isActive = !item.isActive
        let payload = CustomerFormPayload(
            customer: modified,
            amount: modified.amount,
            quantity: modified.quantity,
            rate: modified.rate,
            creationDate: modified.creationDate,
            startDate: modified.startDate,
            completionDate: modified.completionDate
        )
        Task {
            try? await formService.updateCustomer(id: item.id, payload: payload)
        }
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
