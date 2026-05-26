//
//  CustomerUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Customer List
struct CustomerUI: View {
    @AppStorage("color") private var color: Int?
    @StateObject private var viewModel: CustomerData
    @StateObject private var pickerviewModel: PickerDataModel
    
    private let db = Firestore.firestore()
    private let notificationManager = NotificationManager.shared
    
    @State private var searchText = ""
    @State private var isAddingCustomer = false
    @State private var isActiveOnly = false
    @State private var selectedSort: SortType = .date
    
    init(viewModel: CustomerData = CustomerData(), pickerviewModel: PickerDataModel = PickerDataModel()) {
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
    
    private var filteredItems: [customerItem] {
        let items = isActiveOnly ? viewModel.items.filter { $0.active == "1" } : viewModel.items
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.lastname.localizedCaseInsensitiveContains(query) ||
            $0.first.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
    }
    
    private var displayedItems: [customerItem] {
        switch selectedSort {
        case .date:
            return filteredItems
        case .name:
            return filteredItems.sorted { $0.lastname.localizedCaseInsensitiveCompare($1.lastname) == .orderedAscending }
        case .location:
            return filteredItems.sorted { $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending }
        case .active:
            return filteredItems.sorted { $0.active.localizedCaseInsensitiveCompare($1.active) == .orderedDescending }
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
                LeadDetailUI(detail: item)
                    .environmentObject(pickerviewModel)
                    .navigationBarBackButtonHidden(true)
            } label: {
                CellView(data: item, showsComments: !item.comments.isEmpty)
            }
            .contextMenu {
                Button {
                    callPhoneNumber(item.phone)
                } label: {
                    Label("Call", systemImage: "phone")
                }
                Button {
                    scheduleReminder(for: item)
                } label: {
                    Label("Remind", systemImage: "bell")
                }
            }
            .swipeActions(edge: .leading) {
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
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteItems([item])
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onDelete { offsets in
            deleteItems(offsets.map { displayedItems[$0] })
        }
        .onMove { offsets, newOffset in
            viewModel.items.move(fromOffsets: offsets, toOffset: newOffset)
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
            status: "New"
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
    
    private func scheduleReminder(for item: customerItem) {
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
    
    private func callPhoneNumber(_ raw: String) {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
    
    private func deleteItems(_ items: [customerItem]) {
        for item in items {
            db.collection("Customers").document(item.id).delete { error in
                if let error {
                    print(error.localizedDescription)
                    return
                }
                viewModel.items.removeAll { $0.id == item.id }
            }
        }
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
    
    let data: customerItem
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
            Text(data.date)
                .frame(width: Layout.summaryWidth, height: Layout.summaryHeight)
                .font(.caption2)
                .foregroundColor(themeColor)
                .minimumScaleFactor(0.5)
                .padding(.top, 3)

            Text("$\(data.amount).00")
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
        CustomerUI(viewModel: CustomerData())
    }
    .preferredColorScheme(.dark)
}

// MARK: - Customer Data
class CustomerData: ObservableObject {
    @Published var items = [customerItem]()
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd yyyy"
        return formatter
    }()
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    private var listener: ListenerRegistration?
    
    init() {
        fetchData()
    }
    
    func fetchData() {
        isLoading = true
        listener?.remove()
        listener = db.collection("Customers")
            .order(by: "creationDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                
                DispatchQueue.main.async {
                    if let error {
                        print(error.localizedDescription)
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.items = []
                        self.isLoading = false
                        return
                    }
                    
                    self.items = documents.map { self.makeCustomerItem(from: $0) }
                    self.isLoading = false
                }
            }
    }
    
    private func makeCustomerItem(from document: QueryDocumentSnapshot) -> customerItem {
        let stamp = document.get("creationDate") as? Timestamp
        let startStamp = document.get("start") as? Timestamp
        let completeStamp = document.get("completion") as? Timestamp
        let lastStamp = document.get("lastUpdate") as? Timestamp
        let city = document.get("city") as? String ?? ""
        let state = document.get("state") as? String ?? ""
        let zip = document.get("zip") as? String ?? ""
        let amount = document.get("amount") as? NSNumber ?? 0
        let quantity = document.get("quan") as? NSNumber ?? 0
        let salesNo = document.get("salesNo") as? NSNumber ?? 0
        let jobNo = document.get("jobNo") as? NSNumber ?? 0
        let prodNo = document.get("prodNo") as? NSNumber ?? 0
        
        return customerItem(
            id: document.documentID,
            active: document.get("active") as? String ?? "",
            first: document.get("first") as? String ?? "",
            lastname: document.get("lastname") as? String ?? "",
            address: [city, state, zip].filter { !$0.isEmpty }.joined(separator: " "),
            street: document.get("street") as? String ?? "",
            city: city,
            state: state,
            zip: zip,
            amount: numberFormatter.string(from: amount) ?? "0",
            date: dateFormatter.string(from: stamp?.dateValue() ?? Date()),
            rate: document.get("rate") as? String ?? "",
            phone: document.get("phone") as? String ?? "",
            comments: document.get("comments") as? String ?? "",
            spouse: document.get("spouse") as? String ?? "",
            email: document.get("email") as? String ?? "",
            contractor: document.get("contractor") as? String ?? "",
            photo: document.get("photo") as? String ?? "",
            last: dateFormatter.string(from: lastStamp?.dateValue() ?? Date()),
            start: dateFormatter.string(from: startStamp?.dateValue() ?? Date()),
            complete: dateFormatter.string(from: completeStamp?.dateValue() ?? Date()),
            quan: numberFormatter.string(from: quantity) ?? "0",
            salesNo: numberFormatter.string(from: salesNo) ?? "0",
            jobNo: numberFormatter.string(from: jobNo) ?? "0",
            prodNo: numberFormatter.string(from: prodNo) ?? "0",
            l11: "First",
            l12: "Phone",
            l13: "Contractor",
            l14: "Spouse",
            l15: "Email",
            l16: "Last Updated",
            l17: "Photo",
            l21: "Rating",
            l22: "Salesman",
            l23: "Job",
            l24: "Product",
            l25: "Quan",
            l26: "Start",
            l27: "Complete",
            l1datetext: "Sale Date:",
            lnewsTitle: Config.NewsCust,
            status: "Edit",
            formController: "Customer"
        )
    }
    
    deinit {
        listener?.remove()
    }
}

// MARK: - Configuration
enum Config {
    static let NewsLead = "Company to expand to a new web advertising directive this week."
    static let NewsCust = "Check our new line of fabulous windows and siding."
    static let NewsVend = "Peter Balsamo Appointed to United's Board of Directors."
    static let NewsEmploy = "Health benifits cancelled immediately, starting today."
    static let BaseUrl = "http://lotpb.github.io/UnitedWebPage/index.html"
}

// MARK: - Customer Model
struct customerItem: Identifiable {
    var id: String
    var active: String
    var first: String
    var lastname: String
    var address: String
    var street: String
    var city: String
    var state: String
    var zip: String
    var amount: String
    var date: String
    var rate: String
    var phone: String
    var comments: String
    var spouse: String
    var email: String
    var contractor: String
    var photo: String
    var last: String
    var start: String
    var complete: String
    var quan: String
    var salesNo: String
    var jobNo: String
    var prodNo: String
    var l11: String
    var l12: String
    var l13: String
    var l14: String
    var l15: String
    var l16: String
    var l17: String
    var l21: String
    var l22: String
    var l23: String
    var l24: String
    var l25: String
    var l26: String
    var l27: String
    var l1datetext: String
    var lnewsTitle: String
    var status: String
    var formController: String
    
    static var emptyCustomer: customerItem {
        customerItem(
            id: "",
            active: "1",
            first: "",
            lastname: "",
            address: "",
            street: "",
            city: "",
            state: "",
            zip: "",
            amount: "",
            date: "",
            rate: "",
            phone: "",
            comments: "",
            spouse: "",
            email: "",
            contractor: "",
            photo: "",
            last: "",
            start: "",
            complete: "",
            quan: "",
            salesNo: "",
            jobNo: "",
            prodNo: "",
            l11: "First",
            l12: "Phone",
            l13: "Contractor",
            l14: "Spouse",
            l15: "Email",
            l16: "Last Updated",
            l17: "Photo",
            l21: "Rating",
            l22: "Salesman",
            l23: "Job",
            l24: "Product",
            l25: "Quan",
            l26: "Start",
            l27: "Complete",
            l1datetext: "Sale Date:",
            lnewsTitle: Config.NewsCust,
            status: "New",
            formController: "Customer"
        )
    }
}

// MARK: - Picker Data
class PickerDataModel: ObservableObject {
    @Published var pickSalesman = [String]()
    @Published var pickJob = [String]()
    @Published var pickProduct = [String]()
    @Published var pickContractor = [String]()
    @Published var pickRate = [String]()
    
    init() {
        getData()
    }
    
    func getData() {
        pickSalesman.append(contentsOf: [
            "", "Peter Balsamo", "Adam Monteleone", "John Pellegrino", "Mike Agunzo"
        ])
        pickJob.append(contentsOf: [
            "", "Windows", "Siding", "Doors", "Roofing"
        ])
        pickProduct.append(contentsOf: [
            "", "Alside", "Andersen", "Ideal", "Marvin"
        ])
        pickContractor.append(contentsOf: [
            "", "A & S Home Improvement", "Islandwide Gutters", "Ashland Home Improvement", "John Kat Windows", "Jose Rosa", "Peter Balsamo"
        ])
        pickRate.append(contentsOf: [
            "5", "4", "1"
        ])
    }
}

