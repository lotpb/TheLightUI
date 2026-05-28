//
//  CustomerUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

// MARK: - Customer List
struct CustomerUI: View {
    @AppStorage("color") private var color: Int?
    @StateObject private var viewModel: CustomerData
    @StateObject private var pickerviewModel: PickerDataModel
    @Environment(\.openURL) private var openURL
    
    private let notificationManager = NotificationManager.shared
    private let formService: CustomerFormServicing
    
    @State private var searchText = ""
    @State private var isAddingCustomer = false
    @State private var isActiveOnly = false
    @State private var selectedSort: SortType = .date
    
    @MainActor
    init(
        customerService: CustomerServicing = FirebaseCustomerService(),
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        pickerviewModel: PickerDataModel = PickerDataModel()
    ) {
        self.formService = formService
        _viewModel = StateObject(wrappedValue: CustomerData(customerService: customerService))
        _pickerviewModel = StateObject(wrappedValue: pickerviewModel)
    }

    @MainActor
    init(
        viewModel: CustomerData,
        formService: CustomerFormServicing = FirebaseCustomerFormService(),
        pickerviewModel: PickerDataModel = PickerDataModel()
    ) {
        self.formService = formService
        _viewModel = StateObject(wrappedValue: viewModel)
        _pickerviewModel = StateObject(wrappedValue: pickerviewModel)
    }
    
    private enum SortType: String, CaseIterable, Identifiable {
        case date = "Date"
        case name = "Name"
        case location = "Location"
        case active = "Active"
        
        var id: Self { self }
        
        var systemImage: String {
            switch self {
            case .date: return "clock"
            case .name: return "person"
            case .location: return "location"
            case .active: return "folder"
            }
        }
    }
    
    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }
    
    private var filteredItems: [CustomerItem] {
        let items = isActiveOnly ? viewModel.items.filter(\.isActive) : viewModel.items
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.lastname.localizedCaseInsensitiveContains(query) ||
            $0.first.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var displayedItems: [CustomerItem] {
        switch selectedSort {
        case .date:
            return filteredItems
        case .name:
            return filteredItems.sorted { $0.lastname.localizedCaseInsensitiveCompare($1.lastname) == .orderedAscending }
        case .location:
            return filteredItems.sorted { $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending }
        case .active:
            return filteredItems.sorted { $0.isActive && !$1.isActive }
        }
    }
    
    var body: some View {
        customerList
            .listStyle(.plain)
            .navigationTitle("Customers")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(themeColor)
            .toolbar { toolbarContent }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
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
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            .environmentObject(viewModel)
            .environmentObject(pickerviewModel)
    }

    // MARK: - Content

    private var customerList: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading Customers...")
            } else if viewModel.items.isEmpty {
                Text("No Customers")
            } else {
                activeOnlyToggle
                customerRows
            }
        }
    }
    
    private var activeOnlyToggle: some View {
        Toggle(isOn: $isActiveOnly) {
            Text("\(displayedItems.count) Active Only")
        }
        .toggleStyle(SwitchToggleStyle(tint: themeColor))
    }
    
    private var customerRows: some View {
        ForEach(displayedItems) { item in
            NavigationLink {
                LeadDetailUI(detail: item, formService: formService)
                    .environmentObject(pickerviewModel)
                    .navigationBarBackButtonHidden(true)
            } label: {
                CellView(data: item, showsComments: !item.comments.isEmpty)
            }
            .contextMenu { rowContextMenu(for: item) }
            .swipeActions(edge: .leading) { leadingSwipeActions(for: item) }
            .swipeActions(edge: .trailing) { trailingSwipeActions(for: item) }
        }
        .onDelete { offsets in
            deleteItems(offsets.map { displayedItems[$0] })
        }
        .onMove { offsets, newOffset in
            viewModel.items.move(fromOffsets: offsets, toOffset: newOffset)
        }
    }
    
    @ViewBuilder
    private func rowContextMenu(for item: CustomerItem) -> some View {
        Button {
            openURL.callPhoneNumber(item.phone)
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
            notificationManager.deleteNotifications()
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
            Picker("Sorting options", selection: $selectedSort) {
                ForEach(SortType.allCases) { sort in
                    Label(sort.rawValue, systemImage: sort.systemImage)
                        .tag(sort)
                }
            }
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var addCustomerForm: some View {
        FormUI(
            detail: .emptyCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            status: "New",
            formService: formService
        )
        .environmentObject(viewModel)
        .environmentObject(pickerviewModel)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: { isAddingCustomer = true }) {
                Label("New", systemImage: "plus")
            }

            sortMenu
        }
    }

    // MARK: - Actions
    
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

// MARK: - Customer Cell
struct CellView: View {
    private enum Layout {
        static let avatarSize: CGFloat = 60
        static let actionIconSize: CGFloat = 20
        static let summaryWidth: CGFloat = 90
        static let summaryHeight: CGFloat = 25
    }

    @AppStorage("color") private var color: Int?
    
    let data: CustomerItem
    let showsComments: Bool
    
    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }
    
    var body: some View {
        HStack(alignment: .top) {
            avatar
            customerSummary
            Spacer()
            amountSummary
        }
    }

    private var avatar: some View {
        Image("taylor_swift_profile")
            .resizable()
            .frame(width: Layout.avatarSize, height: Layout.avatarSize, alignment: .topLeading)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .padding(.top, 5)
    }

    private var customerSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.lastname)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.5)
                .padding(.top, 3)

            Text(data.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            rowActions
        }
        .padding(.leading, 10)
    }

    private var rowActions: some View {
        HStack(spacing: 20) {
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

    private var amountSummary: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(data.formattedCreationDate)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .font(.caption2)
                .foregroundColor(themeColor)
                .minimumScaleFactor(0.5)
                .padding(.top, 3)

            Text(data.formattedAmount)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.primary)
                .font(.headline)
        }
    }

    private func actionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: Layout.actionIconSize, height: Layout.actionIconSize)
            .foregroundColor(themeColor)
    }
}

// MARK: - Preview
#Preview("Customers - Dark") {
    NavigationStack {
        CustomerUI()
    }
    .preferredColorScheme(.dark)
}

