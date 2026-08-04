//
//  SnapshotView.swift
//  TheLightUI
//

import Charts
import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
private final class SnapshotViewModel {
    var leadsToday: [CustomerItem] = []
    var customersToday: [CustomerItem] = []
    var salesToday: [CustomerItem] = []
    var salesCompletionCount: Int = 0
    var appointmentsToday: [CustomerItem] = []
    var jobsStartingToday: [CustomerItem] = []
    var activeCustomerCount: Int = 0
    var activeLeadCount: Int = 0
    var totalCustomerSales: Int = 0
    var isLoading = false
    var errorMessage: String?

    init() {}

    init(
        leadsToday: [CustomerItem],
        customersToday: [CustomerItem],
        salesToday: [CustomerItem],
        appointmentsToday: [CustomerItem],
        jobsStartingToday: [CustomerItem]
    ) {
        self.leadsToday = leadsToday
        self.customersToday = customersToday
        self.salesToday = salesToday
        self.appointmentsToday = appointmentsToday
        self.jobsStartingToday = jobsStartingToday
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            isLoading = false
            return
        }
        async let leadsSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.creationDate, isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField(CustomerFirestoreSchema.Field.creationDate, isLessThan: Timestamp(date: end))
            .order(by: CustomerFirestoreSchema.Field.creationDate, descending: true)
            .getDocuments()
        async let apptSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.start, isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField(CustomerFirestoreSchema.Field.start, isLessThan: Timestamp(date: end))
            .order(by: CustomerFirestoreSchema.Field.start, descending: false)
            .getDocuments()
        async let salesSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.completion, isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField(CustomerFirestoreSchema.Field.completion, isLessThan: Timestamp(date: end))
            .order(by: CustomerFirestoreSchema.Field.completion, descending: true)
            .getDocuments()
        async let activeCustomerSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.active, isEqualTo: "1")
            .whereField(CustomerFirestoreSchema.Field.category, isEqualTo: CustomerItem.Category.customer.rawValue)
            .getDocuments()
        async let activeLeadSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.active, isEqualTo: "1")
            .whereField(CustomerFirestoreSchema.Field.category, isEqualTo: CustomerItem.Category.lead.rawValue)
            .getDocuments()
        async let allCustomerSalesSnap = Firestore.firestore()
            .collection(CustomerFirestoreSchema.collection)
            .whereField(CustomerFirestoreSchema.Field.category, isEqualTo: CustomerItem.Category.customer.rawValue)
            .getDocuments()
        do {
            let (leads, appts, sales, activeCustomers, activeLeads, allCustomers) = try await (leadsSnap, apptSnap, salesSnap, activeCustomerSnap, activeLeadSnap, allCustomerSalesSnap)
            let allCreatedToday = leads.documents.map(CustomerItem.init)
            leadsToday = allCreatedToday.filter { CustomerItem.Category.lead.matches($0.category) }
            customersToday = allCreatedToday.filter { CustomerItem.Category.customer.matches($0.category) }
            let allStartToday = appts.documents.map(CustomerItem.init)
            appointmentsToday = allStartToday.filter { CustomerItem.Category.lead.matches($0.category) }
            jobsStartingToday = allStartToday.filter {
                CustomerItem.Category.customer.matches($0.category) &&
                $0.completionDate > $0.startDate
            }
            let fromCompletion = sales.documents.map(CustomerItem.init).filter { $0.amount > 0 }
            salesCompletionCount = fromCompletion.count
            // Also include customers created today with an amount — their completionDate
            // may not be today if the date picker was left unchanged during editing.
            let fromCreation = customersToday.filter { $0.amount > 0 }
            let existingIds = Set(fromCompletion.map(\.id))
            salesToday = fromCompletion + fromCreation.filter { !existingIds.contains($0.id) }
            activeCustomerCount = activeCustomers.documents.count
            activeLeadCount = activeLeads.documents.count
            totalCustomerSales = allCustomers.documents.map(CustomerItem.init).reduce(0) { $0 + $1.amount }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct SnapshotView: View {
    @AppStorage(SettingsUI.color) private var color: Int?
    @Environment(\.tabBarOverlap) private var tabBarOverlap
    @State private var viewModel: SnapshotViewModel

    init() {
        _viewModel = State(initialValue: SnapshotViewModel())
    }

    fileprivate init(viewModel: SnapshotViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    private var salesTotal: Int {
        viewModel.salesToday.reduce(0) { $0 + $1.amount }
    }

    private var customersTotal: Int {
        viewModel.customersToday.reduce(0) { $0 + $1.amount }
    }

    private var barEntries: [SnapshotBarEntry] {
        [
            SnapshotBarEntry(label: "Leads",   count: viewModel.leadsToday.count,        color: themeColor),
            SnapshotBarEntry(label: "Appts",   count: viewModel.appointmentsToday.count, color: .orange),
            SnapshotBarEntry(label: "Customer", count: viewModel.customersToday.count,  color: .indigo),
            SnapshotBarEntry(label: "Jobs",    count: viewModel.jobsStartingToday.count, color: .teal)
        ]
    }

    private var summarySection: some View {
        Section {
            // Stat strip — fixed HStack so cards align with chart columns below
            HStack(spacing: 6) {
                SnapshotStatCard(title: "Leads",     value: "\(viewModel.leadsToday.count)",        color: themeColor)
                    .frame(maxWidth: .infinity)
                SnapshotStatCard(title: "Appts",     value: "\(viewModel.appointmentsToday.count)", color: .orange)
                    .frame(maxWidth: .infinity)
                SnapshotStatCard(title: "Customer", value: "\(viewModel.customersToday.count)",    color: .indigo)
                    .frame(maxWidth: .infinity)
                SnapshotStatCard(
                    title: "Sales",
                    value: CustomerPresentationFormatters.currency.string(from: NSNumber(value: salesTotal)) ?? "$0",
                    color: .green
                )
                .frame(maxWidth: .infinity)
                SnapshotStatCard(title: "Jobs",      value: "\(viewModel.jobsStartingToday.count)", color: .teal)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))

            HStack(spacing: 6) {
                SnapshotStatCard(title: "Active Leads", value: "\(viewModel.activeLeadCount)", color: themeColor)
                    .frame(maxWidth: .infinity)
                SnapshotStatCard(title: "Active Customers", value: "\(viewModel.activeCustomerCount)", color: .indigo)
                    .frame(maxWidth: .infinity)
                SnapshotStatCard(
                    title: "Total Sales",
                    value: CustomerPresentationFormatters.currency.string(from: NSNumber(value: viewModel.totalCustomerSales)) ?? "$0",
                    color: .green
                )
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))

            // Count bar chart — only shown when at least one category has data
            if barEntries.contains(where: { $0.count > 0 }) {
                Chart(barEntries) { entry in
                    BarMark(
                        x: .value("Category", entry.label),
                        y: .value("Count", entry.count)
                    )
                    .foregroundStyle(entry.color)
                    .cornerRadius(6)
                    .annotation(position: .top, alignment: .center) {
                        if entry.count > 0 {
                            Text("\(entry.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 150)
                .padding(.vertical, 8)
                .animation(.easeInOut(duration: 0.4), value: barEntries.map(\.count))
            }
        } header: {
            HStack {
                Text("Today's Summary")
                    .foregroundStyle(themeColor)
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        List {
            summarySection

            Section {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if viewModel.leadsToday.isEmpty {
                    Text("No leads today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.leadsToday) { item in
                        CustomerCellView(data: item, showsComments: !item.comments.isEmpty, showsActions: false, color: color)
                    }
                }
            } header: {
                HStack {
                    Text("Leads Today")
                        .foregroundStyle(themeColor)
                    Spacer()
                    if !viewModel.leadsToday.isEmpty {
                        Text("\(viewModel.leadsToday.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(themeColor, in: Capsule())
                    }
                }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.appointmentsToday.isEmpty {
                    Text("No appointments today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.appointmentsToday) { item in
                        CustomerCellView(data: item, showsComments: !item.comments.isEmpty, showsActions: false, color: color)
                    }
                }
            } header: {
                HStack {
                    Text("Appointments Today")
                        .foregroundStyle(.orange)
                    Spacer()
                    if !viewModel.appointmentsToday.isEmpty {
                        Text("\(viewModel.appointmentsToday.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                    }
                }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.customersToday.isEmpty {
                    Text("No customers today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.customersToday) { item in
                        CustomerCellView(data: item, showsComments: !item.comments.isEmpty, showsActions: false, color: color)
                    }
                }
            } header: {
                HStack {
                    Text("Customers Today")
                        .foregroundStyle(.indigo)
                    Spacer()
                    if !viewModel.customersToday.isEmpty {
                        Text("\(viewModel.customersToday.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.indigo, in: Capsule())
                    }
                }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.salesToday.isEmpty {
                    Text("No sales today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.salesToday) { item in
                        CustomerCellView(data: item, showsComments: !item.comments.isEmpty, showsActions: false, color: color)
                    }
                }
            } header: {
                HStack {
                    Text("Sales Today")
                        .foregroundStyle(.green)
                    Spacer()
                    if !viewModel.salesToday.isEmpty {
                        Text(CustomerPresentationFormatters.currency.string(from: NSNumber(value: salesTotal)) ?? "$0")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green, in: Capsule())
                    }
                }
            }

            Section {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.jobsStartingToday.isEmpty {
                    Text("No jobs starting today")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.jobsStartingToday) { item in
                        CustomerCellView(data: item, showsComments: !item.comments.isEmpty, showsActions: false, color: color)
                    }
                }
            } header: {
                HStack {
                    Text("Jobs in Progress")
                        .foregroundStyle(.teal)
                    Spacer()
                    if !viewModel.jobsStartingToday.isEmpty {
                        Text("\(viewModel.jobsStartingToday.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.teal, in: Capsule())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: tabBarOverlap)
                .allowsHitTesting(false)
        }
        .navigationTitle("Snapshot")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeColor)
        .task {
            await viewModel.fetch()
        }
        .refreshable {
            await viewModel.fetch()
        }
    }
}

// MARK: - Summary section helpers

private struct SnapshotBarEntry: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let color: Color
}

private struct SnapshotStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(height: 30)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func previewItem(
    id: String, first: String, last: String,
    city: String, amount: Int, category: String,
    phone: String = "555-555-5555", comments: String = ""
) -> CustomerItem {
    let today = Date()
    return CustomerItem(
        id: id, isActive: true,
        first: first, lastname: last,
        street: "123 Main St", city: city, state: "FL", zip: "33432",
        amount: amount, creationDate: today, rate: "5",
        phone: phone, comments: comments,
        spouse: "", email: "\(first.lowercased())@example.com",
        contractor: "", photo: "",
        lastUpdateDate: today, startDate: today, completionDate: today,
        quantity: 1, salesman: "Mike", job: "Windows", product: "Storm Guard",
        category: category
    )
}

#Preview {
    let vm = SnapshotViewModel(
        leadsToday: [
            previewItem(id: "L1", first: "James",  last: "Rosch",    city: "Boca Raton",    amount: 0,    category: "Lead", phone: "561-555-0101", comments: "Interested in siding"),
            previewItem(id: "L2", first: "Maria",  last: "Torres",   city: "Delray Beach",  amount: 0,    category: "Lead", phone: "561-555-0102")
        ],
        customersToday: [
            previewItem(id: "C1", first: "Robert", last: "Balsamo",  city: "Boynton Beach", amount: 0,    category: "Customer")
        ],
        salesToday: [
            previewItem(id: "S1", first: "Nancy",  last: "Greene",   city: "Lake Worth",    amount: 8500, category: "Customer"),
            previewItem(id: "S2", first: "Paul",   last: "Mancini",  city: "Coral Springs", amount: 4200, category: "Customer")
        ],
        appointmentsToday: [
            previewItem(id: "A1", first: "Carol",  last: "White",    city: "Pompano Beach", amount: 0,    category: "Lead", phone: "954-555-0301")
        ],
        jobsStartingToday: [
            previewItem(id: "J1", first: "Dennis", last: "Ford",     city: "Plantation",    amount: 6100, category: "Customer"),
            previewItem(id: "J2", first: "Susan",  last: "Kim",      city: "Weston",        amount: 3800, category: "Customer")
        ]
    )

    NavigationStack {
        SnapshotView(viewModel: vm)
    }
    .preferredColorScheme(.dark)
}
