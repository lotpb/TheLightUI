//
//  ReportsView.swift
//  TheLightUI
//

import SwiftUI
import Charts

// MARK: - Period

private enum ReportPeriod: String, CaseIterable, Identifiable {
    case week, month, lastMonth, quarter, year, last12, all
    var id: String { rawValue }

    var label: String {
        switch self {
        case .week:      return "This Week"
        case .month:     return "This Month"
        case .lastMonth: return "Last Month"
        case .quarter:   return "This Quarter"
        case .year:      return "This Year"
        case .last12:    return "Last 12M"
        case .all:       return "All Time"
        }
    }

    func range() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .week:
            let wd = cal.component(.weekday, from: now) - 1
            let s  = cal.date(byAdding: .day, value: -wd, to: cal.startOfDay(for: now)) ?? now
            return (s, now)
        case .month:
            return (cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now, now)
        case .lastMonth:
            let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            let prevMonth = cal.date(byAdding: .month, value: -1, to: thisMonth) ?? now
            let lastDay   = cal.date(byAdding: .day, value: -1, to: thisMonth) ?? now
            return (prevMonth, lastDay)
        case .quarter:
            let m = cal.component(.month, from: now) - 1
            let qStart = (m / 3) * 3 + 1
            var c = cal.dateComponents([.year], from: now)
            c.month = qStart; c.day = 1
            return (cal.date(from: c) ?? now, now)
        case .year:
            var c = cal.dateComponents([.year], from: now)
            c.month = 1; c.day = 1
            return (cal.date(from: c) ?? now, now)
        case .last12:
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            return (cal.date(byAdding: .month, value: -11, to: monthStart) ?? now, now)
        case .all:
            return (Date(timeIntervalSince1970: 0), now)
        }
    }
}

// MARK: - Salesman sort

private enum SmSort: String, CaseIterable {
    case revenue   = "Revenue"
    case leads     = "Leads"
    case customers = "Customers"
}

// MARK: - Data models

private struct SalesmanRow: Identifiable {
    let name: String
    var id: String { name }
    var leads: Int
    var customers: Int
    var revenue: Int
}

private struct SourceRow: Identifiable {
    let source: String
    var id: String { source }
    var count: Int
    var revenue: Int
}

private struct TrendPoint: Identifiable {
    let monthKey: String   // "yyyy-MM" — used for grouping
    let monthLabel: String // "Jan 24"  — shown on axis
    var id: String { monthKey }
    var revenue: Int
    var leads: Int
    var customers: Int
}

// MARK: - Helpers

private let cal = Calendar.current

private func fmtShort(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "$%.1fM", Double(n) / 1_000_000) }
    if n >= 1_000     { return String(format: "$%.1fK", Double(n) / 1_000) }
    return "$\(n)"
}

private func fmtFull(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: n)) ?? "$\(n)"
}

// MARK: - ReportsView

@MainActor
struct ReportsView: View {
    let customerStore: CustomerStore

    @State private var period: ReportPeriod = .month
    @State private var smSort: SmSort = .revenue

    // MARK: Derived data

    private var all: [CustomerItem] { customerStore.items }

    private var periodItems: [CustomerItem] {
        let (start, end) = period.range()
        return all.filter { $0.creationDate >= start && $0.creationDate <= end }
    }

    private var kpi: (leads: Int, customers: Int, revenue: Int, avgDeal: Int) {
        let leads = periodItems.filter { $0.category.lowercased() == "lead" }
        let custs = periodItems.filter { $0.category.lowercased() == "customer" }
        let rev   = custs.reduce(0) { $0 + max(0, $1.amount) }
        return (leads.count, custs.count, rev, custs.isEmpty ? 0 : rev / custs.count)
    }

    private var salesmanRows: [SalesmanRow] {
        var map: [String: SalesmanRow] = [:]
        for c in all {
            let cat = c.category.lowercased()
            guard cat == "lead" || cat == "customer" else { continue }
            let name = c.salesman.trimmingCharacters(in: .whitespaces).isEmpty ? "Unassigned" : c.salesman
            var row  = map[name] ?? SalesmanRow(name: name, leads: 0, customers: 0, revenue: 0)
            if cat == "lead" {
                row.leads += 1
            } else {
                row.customers += 1
                row.revenue   += max(0, c.amount)
            }
            map[name] = row
        }
        return map.values.sorted { a, b in
            switch smSort {
            case .revenue:   return a.revenue   > b.revenue
            case .leads:     return a.leads     > b.leads
            case .customers: return a.customers > b.customers
            }
        }
    }

    private var sourceRows: [SourceRow] {
        var map: [String: SourceRow] = [:]
        for c in all {
            let cat = c.category.lowercased()
            guard cat == "lead" || cat == "customer" else { continue }
            let src = c.adNo.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown" : c.adNo
            var row = map[src] ?? SourceRow(source: src, count: 0, revenue: 0)
            row.count   += 1
            row.revenue += max(0, c.amount)
            map[src] = row
        }
        return Array(map.values.sorted { $0.count > $1.count }.prefix(10))
    }

    private var trendData: [TrendPoint] {
        let now = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let keyFmt   = DateFormatter(); keyFmt.dateFormat   = "yyyy-MM"
        let labelFmt = DateFormatter(); labelFmt.dateFormat = "MMM yy"

        var points: [TrendPoint] = (0..<12).reversed().compactMap { offset -> TrendPoint? in
            guard let d = cal.date(byAdding: .month, value: -offset, to: monthStart) else { return nil }
            return TrendPoint(monthKey: keyFmt.string(from: d), monthLabel: labelFmt.string(from: d),
                              revenue: 0, leads: 0, customers: 0)
        }
        var indexMap: [String: Int] = [:]
        for (i, p) in points.enumerated() { indexMap[p.monthKey] = i }

        for c in all {
            let key = keyFmt.string(from: c.creationDate)
            guard let idx = indexMap[key] else { continue }
            let cat = c.category.lowercased()
            if cat == "customer" {
                points[idx].revenue   += max(0, c.amount)
                points[idx].customers += 1
            } else if cat == "lead" {
                points[idx].leads += 1
            }
        }
        return points
    }

    private var hasTrend: Bool {
        trendData.contains { $0.revenue > 0 || $0.leads > 0 }
    }

    // MARK: CSV export

    private var csvText: String {
        var lines = ["Salesman,Leads,Customers,Revenue,Avg Deal,Conv %"]
        for r in salesmanRows {
            let avg  = r.customers > 0 ? fmtFull(r.revenue / r.customers) : "—"
            let conv = r.leads > 0 ? String(format: "%.0f%%", Double(r.customers) / Double(r.leads) * 100) : "—"
            lines.append("\"\(r.name)\",\(r.leads),\(r.customers),\(fmtFull(r.revenue)),\(avg),\(conv)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                periodPicker
                if customerStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else {
                    kpiCards
                    if hasTrend {
                        trendChartCard
                    }
                    salesmanCard
                    if !sourceRows.isEmpty {
                        sourceCard
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: csvText,
                    subject: Text("Salesman Report"),
                    message: Text("Salesman performance export")
                ) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Period picker

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ReportPeriod.allCases) { p in
                    Button(p.label) { period = p }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(period == p ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(period == p ? Color.white : Color.secondary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - KPI cards

    private var kpiCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            RptKpiCard(label: "New Leads",     value: "\(kpi.leads)",        green: false)
            RptKpiCard(label: "New Customers", value: "\(kpi.customers)",     green: false)
            RptKpiCard(label: "Revenue",       value: fmtShort(kpi.revenue), green: true)
            RptKpiCard(label: "Avg Deal",      value: fmtShort(kpi.avgDeal), green: false)
        }
    }

    // MARK: - Trend chart

    private var trendChartCard: some View {
        let data   = trendData
        let maxRev = data.map(\.revenue).max() ?? 1
        let maxLds = data.map(\.leads).max() ?? 1
        let scale  = maxLds > 0 ? Double(maxRev) / Double(maxLds) : 1.0

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("Revenue Trend")
                    .font(.subheadline.weight(.semibold))
                Text("(last 12 months)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            Chart {
                ForEach(data) { d in
                    BarMark(
                        x: .value("Month", d.monthLabel),
                        y: .value("Revenue", Double(d.revenue))
                    )
                    .foregroundStyle(Color.indigo.gradient)
                    .cornerRadius(3)

                    LineMark(
                        x: .value("Month", d.monthLabel),
                        y: .value("Leads", Double(d.leads) * scale)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(16)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(fmtShort(Int(v))).font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.indigo).frame(width: 12, height: 10)
                    Text("Revenue").font(.caption2).foregroundStyle(Color.secondary)
                }
                HStack(spacing: 5) {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text("Leads (scaled)").font(.caption2).foregroundStyle(Color.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Salesman card

    private var salesmanCard: some View {
        VStack(spacing: 0) {
            // Header + sort
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Salesman Performance")
                        .font(.subheadline.weight(.semibold))
                    Text("all time")
                        .font(.caption2).foregroundStyle(Color.secondary)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(SmSort.allCases, id: \.self) { s in
                        Button(s.rawValue) { smSort = s }
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(smSort == s ? Color.accentColor.opacity(0.15) : Color.clear)
                            .foregroundStyle(smSort == s ? Color.accentColor : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Divider()

            if salesmanRows.isEmpty {
                Text("No data")
                    .font(.subheadline).foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(salesmanRows.indices, id: \.self) { i in
                        salesmanRow(salesmanRows[i], rank: i + 1)
                        if i < salesmanRows.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func salesmanRow(_ r: SalesmanRow, rank: Int) -> some View {
        let conv = r.leads > 0 ? Int(Double(r.customers) / Double(r.leads) * 100) : nil
        let avg  = r.customers > 0 ? fmtShort(r.revenue / r.customers) : "—"
        let convColor: Color = conv.map { $0 >= 50 ? .green : $0 >= 25 ? .yellow : .secondary } ?? .secondary

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(rank)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color(.tertiaryLabel))
                Text(r.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(r.revenue > 0 ? fmtFull(r.revenue) : "—")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(r.revenue > 0 ? Color.green : Color.secondary)
            }
            HStack(spacing: 10) {
                Label("\(r.leads) leads", systemImage: "person.badge.plus")
                    .foregroundStyle(Color.indigo)
                Label("\(r.customers) cust", systemImage: "checkmark.circle")
                    .foregroundStyle(Color.teal)
                Text("Avg \(avg)")
                    .foregroundStyle(Color.secondary)
                Spacer()
                if let c = conv {
                    Text("Conv \(c)%")
                        .foregroundStyle(convColor)
                        .fontWeight(.semibold)
                }
            }
            .font(.caption)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - Source card

    private var sourceCard: some View {
        let rows  = sourceRows
        let total = rows.reduce(0) { $0 + $1.count }

        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Lead Sources")
                        .font(.subheadline.weight(.semibold))
                    Text("top 10, all time")
                        .font(.caption2).foregroundStyle(Color.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Divider()

            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { i in
                    sourceRow(rows[i], total: total)
                    if i < rows.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sourceRow(_ r: SourceRow, total: Int) -> some View {
        let pct = total > 0 ? Double(r.count) / Double(total) : 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(r.source)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(r.count) records")
                    if r.revenue > 0 {
                        Text("·")
                        Text(fmtFull(r.revenue)).foregroundStyle(Color.green)
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.caption.weight(.semibold).monospacedDigit())
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 4)
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * CGFloat(pct), height: 4)
                    }
                }
                .frame(width: 80, height: 4)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

// MARK: - KPI Card

private struct RptKpiCard: View {
    let label: String
    let value: String
    let green: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(green ? Color.green : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
