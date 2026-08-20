//
//  HeatMapView.swift
//  TheLightUI
//

import SwiftUI
import Charts

// MARK: - Types

private enum HeatCatFilter: String, CaseIterable {
    case all      = "All"
    case lead     = "Leads"
    case customer = "Customers"
}

private enum HeatGeoView: String, CaseIterable {
    case state = "By State"
    case city  = "By City"
}

private enum HeatSortKey: String, CaseIterable, Identifiable {
    case total     = "Total"
    case leads     = "Leads"
    case customers = "Customers"
    case revenue   = "Revenue"
    var id: String { rawValue }
}

// MARK: - Data models

private struct GeoState: Identifiable {
    var id: String { state }
    let state: String
    var total: Int
    var leads: Int
    var customers: Int
    var revenue: Int
    var cities: [GeoCity]
}

private struct GeoCity: Identifiable {
    var id: String { key }
    let key: String
    let city: String
    let state: String
    var total: Int
    var leads: Int
    var customers: Int
    var revenue: Int
}

private struct HeatChartItem: Identifiable {
    let id = UUID()
    let name: String
    let total: Int
    let leads: Int
    let customers: Int
}

// MARK: - Helpers

private func heatColor(intensity: Double) -> Color {
    let t = max(0, min(1, intensity))
    // Cool #1e3a5f → Hot #f97316
    let r = 30.0  + t * (249.0 - 30.0)
    let g = 58.0  + t * (115.0 - 58.0)
    let b = 95.0  + t * (22.0  - 95.0)
    return Color(red: r / 255, green: g / 255, blue: b / 255)
}

private func fmtRevenue(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "$%.1fM", Double(n) / 1_000_000) }
    if n >= 1_000     { return String(format: "$%.1fK", Double(n) / 1_000) }
    return "$\(n)"
}

private func normGeo(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces).uppercased() }

// MARK: - HeatMapView

@MainActor
struct HeatMapView: View {
    let customerStore: CustomerStore

    @State private var catFilter:   HeatCatFilter = .all
    @State private var repFilter    = ""
    @State private var geoView:     HeatGeoView   = .state
    @State private var sortKey:     HeatSortKey   = .total
    @State private var sortAsc      = false
    @State private var stateFilter: String?        // drill-down

    // MARK: - Derived data

    private var reps: [String] {
        Set(customerStore.items.compactMap { $0.salesman.isEmpty ? nil : $0.salesman }).sorted()
    }

    private var filtered: [CustomerItem] {
        customerStore.items.filter { c in
            switch catFilter {
            case .lead:     if normGeo(c.category) != "LEAD"     { return false }
            case .customer: if normGeo(c.category) != "CUSTOMER" { return false }
            case .all:      break
            }
            if !repFilter.isEmpty, c.salesman != repFilter { return false }
            return true
        }
    }

    private var stateRows: [GeoState] {
        var map: [String: GeoState] = [:]
        for c in filtered {
            let st   = normGeo(c.state).isEmpty ? "—" : normGeo(c.state)
            let city = normGeo(c.city).isEmpty  ? "—" : normGeo(c.city)
            let cityKey = "\(city), \(st)"
            let rev  = max(0, c.amount)
            let isLead = normGeo(c.category) == "LEAD"
            let isCust = normGeo(c.category) == "CUSTOMER"

            if map[st] == nil {
                map[st] = GeoState(state: st, total: 0, leads: 0, customers: 0, revenue: 0, cities: [])
            }
            map[st]!.total    += 1
            if isLead { map[st]!.leads    += 1 }
            if isCust { map[st]!.customers += 1 }
            map[st]!.revenue += rev

            if let idx = map[st]!.cities.firstIndex(where: { $0.key == cityKey }) {
                map[st]!.cities[idx].total    += 1
                if isLead { map[st]!.cities[idx].leads    += 1 }
                if isCust { map[st]!.cities[idx].customers += 1 }
                map[st]!.cities[idx].revenue += rev
            } else {
                map[st]!.cities.append(GeoCity(
                    key: cityKey, city: city, state: st,
                    total: 1,
                    leads: isLead ? 1 : 0,
                    customers: isCust ? 1 : 0,
                    revenue: rev
                ))
            }
        }
        return Array(map.values)
    }

    private var sortedStates: [GeoState] {
        stateRows.sorted { a, b in
            let diff: Int
            switch sortKey {
            case .total:     diff = a.total     - b.total
            case .leads:     diff = a.leads     - b.leads
            case .customers: diff = a.customers - b.customers
            case .revenue:   diff = a.revenue   - b.revenue
            }
            return sortAsc ? diff < 0 : diff > 0
        }
    }

    private var cityRows: [GeoCity] {
        stateRows
            .filter { stateFilter == nil || $0.state == stateFilter }
            .flatMap(\.cities)
    }

    private var sortedCities: [GeoCity] {
        cityRows.sorted { a, b in
            let diff: Int
            switch sortKey {
            case .total:     diff = a.total     - b.total
            case .leads:     diff = a.leads     - b.leads
            case .customers: diff = a.customers - b.customers
            case .revenue:   diff = a.revenue   - b.revenue
            }
            return sortAsc ? diff < 0 : diff > 0
        }
    }

    private var maxTotal: Int {
        let rows = geoView == .state ? stateRows.map(\.total) : cityRows.map(\.total)
        return max(rows.max() ?? 1, 1)
    }

    // KPIs
    private var totalRevenue: Int { filtered.reduce(0) { $0 + max(0, $1.amount) } }
    private var topState:     String { sortedStates.first?.state ?? "—" }
    private var topStateCount: Int   { sortedStates.first?.total ?? 0 }
    private var topCity:      String { sortedCities.first?.city  ?? "—" }
    private var topCityCount: Int    { sortedCities.first?.total ?? 0 }

    // Chart data (top 15)
    private var chartItems: [HeatChartItem] {
        let rows: [(name: String, total: Int, leads: Int, customers: Int)]
        if geoView == .state {
            rows = sortedStates.prefix(15).map { ($0.state, $0.total, $0.leads, $0.customers) }
        } else {
            let src = stateFilter == nil ? sortedCities : sortedCities.filter { $0.state == stateFilter }
            rows = src.prefix(15).map { ($0.city, $0.total, $0.leads, $0.customers) }
        }
        return rows.map { HeatChartItem(name: $0.name, total: $0.total, leads: $0.leads, customers: $0.customers) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                filterBar
                kpiCards
                if !chartItems.isEmpty {
                    barChartSection
                }
                if geoView == .state {
                    heatGrid
                }
                if geoView == .city, let sf = stateFilter {
                    cityGrid(for: sf)
                }
                tableSection
            }
            .padding()
        }
        .navigationTitle("Geographic Distribution")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if stateFilter != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        stateFilter = nil
                        geoView = .state
                    } label: {
                        Label("All States", systemImage: "chevron.left")
                    }
                }
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                // Category toggle
                HStack(spacing: 0) {
                    ForEach(HeatCatFilter.allCases, id: \.self) { f in
                        Button(f.rawValue) { catFilter = f }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(catFilter == f ? Color.accentColor : Color.clear)
                            .foregroundStyle(catFilter == f ? Color.white : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                // Rep filter
                if !reps.isEmpty {
                    repMenu
                }
            }

            // View toggle
            HStack(spacing: 0) {
                ForEach(HeatGeoView.allCases, id: \.self) { v in
                    Button(v.rawValue) {
                        geoView = v
                        if v == .state { stateFilter = nil }
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(geoView == v ? Color.accentColor : Color.clear)
                    .foregroundStyle(geoView == v ? Color.white : Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Spacer()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var repMenu: some View {
        Menu {
            Button { repFilter = "" } label: {
                Label("All Salespeople", systemImage: repFilter.isEmpty ? "checkmark" : "person.2")
            }
            Divider()
            ForEach(reps, id: \.self) { rep in
                Button { repFilter = rep } label: {
                    Label(rep, systemImage: repFilter == rep ? "checkmark" : "person")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(repFilter.isEmpty ? "All Reps" : repFilter)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - KPI Cards

    private var kpiCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            KpiCard(label: "Total Records",
                    value: "\(filtered.count)",
                    sub: "\(stateRows.count) state\(stateRows.count == 1 ? "" : "s")")
            KpiCard(label: "Top State",
                    value: topState,
                    sub: "\(topStateCount) records")
            KpiCard(label: "Top City",
                    value: topCity,
                    sub: "\(topCityCount) records")
            KpiCard(label: "Total Revenue",
                    value: fmtRevenue(totalRevenue),
                    sub: "from customers")
        }
    }

    // MARK: - Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let title = "Top \(min(chartItems.count, 15)) \(geoView == .state ? "States" : "Cities")\(stateFilter.map { " in \($0)" } ?? "")"
            Text(title)
                .font(.subheadline.weight(.semibold))

            Chart(chartItems) { item in
                BarMark(
                    x: .value("Count", item.total),
                    y: .value("Location", item.name)
                )
                .foregroundStyle(heatColor(intensity: Double(item.total) / Double(maxTotal)))
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .frame(height: CGFloat(chartItems.count) * 22 + 20)

            Text("Color intensity indicates concentration — fewer (cool blue) to more (warm orange)")
                .font(.caption2)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - State Heat Grid

    private var heatGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("State Heat Map")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 6)], spacing: 6) {
                ForEach(sortedStates) { sr in
                    let intensity = Double(sr.total) / Double(maxTotal)
                    Button {
                        stateFilter = stateFilter == sr.state ? nil : sr.state
                        geoView = stateFilter == nil ? .state : .city
                    } label: {
                        VStack(spacing: 2) {
                            Text(sr.state)
                                .font(.system(size: 11, weight: .bold))
                                .lineLimit(1)
                            Text("\(sr.total)")
                                .font(.system(size: 9))
                                .opacity(0.85)
                        }
                        .frame(width: 54, height: 44)
                        .background(heatColor(intensity: intensity))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(stateFilter == sr.state ? 0.9 : 0), lineWidth: 2)
                        )
                        .scaleEffect(stateFilter == sr.state ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: stateFilter)
                    }
                    .buttonStyle(.plain)
                }
            }

            if sortedStates.isEmpty {
                Text("No geographic data available.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            // Legend
            HStack(spacing: 6) {
                Text("Fewer")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
                LinearGradient(
                    colors: [heatColor(intensity: 0), heatColor(intensity: 1)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 6)
                .clipShape(Capsule())
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - City Grid

    private func cityGrid(for state: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cities in \(state)")
                .font(.subheadline.weight(.semibold))

            let cities = sortedCities.filter { $0.state == state }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                ForEach(cities) { cr in
                    let intensity = Double(cr.total) / Double(maxTotal)
                    VStack(spacing: 2) {
                        Text(cr.city)
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text("\(cr.total)")
                            .font(.system(size: 9))
                            .opacity(0.85)
                    }
                    .frame(minWidth: 70, minHeight: 44)
                    .padding(.horizontal, 4)
                    .background(heatColor(intensity: intensity))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if cities.isEmpty {
                Text("No city data for \(state).")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Data Table

    private var tableSection: some View {
        VStack(spacing: 0) {
            // Section header + sort
            HStack {
                let count = geoView == .state ? stateRows.count : cityRows.count
                let label = geoView == .state
                    ? "All States (\(count))"
                    : "All Cities\(stateFilter.map { " in \($0)" } ?? "") (\(count))"
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                sortMenu
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))

            Divider()

            // Rows
            let tableRows: [any GeoRowProtocol] = geoView == .state
                ? sortedStates.map { $0 as any GeoRowProtocol }
                : sortedCities.filter { stateFilter == nil || $0.state == stateFilter }
                              .map { $0 as any GeoRowProtocol }

            if tableRows.isEmpty {
                Text("No records match the selected filters.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(.secondarySystemGroupedBackground))
            } else {
                VStack(spacing: 0) {
                    ForEach(tableRows.indices, id: \.self) { i in
                        let row = tableRows[i]
                        geoTableRow(row, isLast: i == tableRows.count - 1)
                        if i < tableRows.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(HeatSortKey.allCases) { key in
                Button {
                    if sortKey == key { sortAsc.toggle() }
                    else { sortKey = key; sortAsc = false }
                } label: {
                    HStack {
                        Text(key.rawValue)
                        if sortKey == key {
                            Image(systemName: sortAsc ? "arrow.up" : "arrow.down")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Sort: \(sortKey.rawValue)")
                    .font(.caption.weight(.medium))
                Image(systemName: sortAsc ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private func geoTableRow(_ row: any GeoRowProtocol, isLast: Bool) -> some View {
        let intensity = Double(row.total) / Double(maxTotal)
        let convPct   = row.total > 0 ? Int(Double(row.customers) / Double(row.total) * 100) : 0
        let isState   = row is GeoState

        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Heat indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(heatColor(intensity: intensity))
                    .frame(width: 4, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(row.displayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if isState {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        Spacer()
                        Text("\(row.total)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)
                    }
                    HStack(spacing: 8) {
                        Label("\(row.leads)", systemImage: "person.badge.plus")
                            .foregroundStyle(Color.indigo)
                        Label("\(row.customers)", systemImage: "person.fill.checkmark")
                            .foregroundStyle(Color.green)
                        Text(fmtRevenue(row.revenue))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("Conv \(convPct)%")
                            .foregroundStyle(Color.secondary)
                    }
                    .font(.caption)

                    // Concentration bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 4)
                            Capsule()
                                .fill(heatColor(intensity: intensity))
                                .frame(width: geo.size.width * CGFloat(intensity), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                if let state = row as? GeoState {
                    stateFilter = state.state
                    geoView = .city
                }
            }
        }
    }
}

// MARK: - Protocol for unified row rendering

private protocol GeoRowProtocol {
    var displayName: String { get }
    var total: Int { get }
    var leads: Int { get }
    var customers: Int { get }
    var revenue: Int { get }
}

extension GeoState: GeoRowProtocol {
    var displayName: String { state }
}

extension GeoCity: GeoRowProtocol {
    var displayName: String { city }
}

// MARK: - KPI Card

private struct KpiCard: View {
    let label: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(value.count > 8 ? .headline.weight(.bold) : .title2.weight(.bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
