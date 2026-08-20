//
//  ForecastView.swift
//  TheLightUI
//

import SwiftUI
import Charts

// MARK: - Enums

private enum FcstPeriod: String, CaseIterable {
    case ytd     = "YTD"
    case sixM    = "6M"
    case twelveM = "12M"
    case all     = "All"
}

private enum FcstWindow: Int, CaseIterable {
    case three  = 3
    case six    = 6
    case twelve = 12
    var label: String { "+\(rawValue)mo" }
}

// MARK: - Data Types

private struct FcstActualPoint: Identifiable {
    let id    = UUID()
    let label : String
    let value : Double
}

private struct FcstBandPoint: Identifiable {
    let id    = UUID()
    let label : String
    let low   : Double
    let high  : Double
}

private struct FcstProjPoint: Identifiable {
    let id    = UUID()
    let label : String
    let value : Double
}

private struct FcstDealPoint: Identifiable {
    let id    = UUID()
    let label : String
    let count : Int
}

private struct FcstRepRow: Identifiable {
    var id: String { rep }
    let rep     : String
    let revenue : Double
    let deals   : Int
    var avg: Double { deals > 0 ? revenue / Double(deals) : 0 }
}

private struct FcstMonthRow: Identifiable {
    let id        = UUID()
    let label     : String
    let projected : Double
    let low       : Double
    let high      : Double
}

private struct PipelineRow: Identifiable {
    var id: String { cid }
    let cid      : String
    let name     : String
    let salesman : String
    let amount   : Double
}

// MARK: - Helpers

private let epochFloor = Date(timeIntervalSince1970: 86_400)

private func validDate(_ d: Date) -> Bool { d > epochFloor }

private func revenueDate(_ c: CustomerItem) -> Date? {
    if validDate(c.completionDate) { return c.completionDate }
    if validDate(c.startDate)      { return c.startDate }
    return nil
}

private func monthKey(_ d: Date) -> String {
    let c = Calendar.current
    return "\(c.component(.year, from: d))-\(String(format: "%02d", c.component(.month, from: d)))"
}

private func monthLabel(_ key: String) -> String {
    let parts = key.split(separator: "-")
    guard parts.count == 2, let y = Int(parts[0]), let m = Int(parts[1]) else { return key }
    var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = 1
    guard let date = Calendar.current.date(from: comps) else { return key }
    let fmt = DateFormatter(); fmt.dateFormat = "MMM yy"
    return fmt.string(from: date)
}

private func lastNMonthKeys(_ n: Int) -> [String] {
    let cal = Calendar.current
    let now = Date()
    return (0..<n).reversed().map { i in
        monthKey(cal.date(byAdding: .month, value: -i, to: now) ?? now)
    }
}

private func nextNMonthKeys(_ n: Int) -> [String] {
    let cal = Calendar.current
    let now = Date()
    return (1...n).map { i in
        monthKey(cal.date(byAdding: .month, value: i, to: now) ?? now)
    }
}

private func linReg(_ pts: [(x: Double, y: Double)]) -> (slope: Double, intercept: Double) {
    guard pts.count >= 2 else { return (0, pts.first?.y ?? 0) }
    let n   = Double(pts.count)
    let sx  = pts.reduce(0.0) { $0 + $1.x }
    let sy  = pts.reduce(0.0) { $0 + $1.y }
    let sxy = pts.reduce(0.0) { $0 + $1.x * $1.y }
    let sxx = pts.reduce(0.0) { $0 + $1.x * $1.x }
    let den = n * sxx - sx * sx
    guard den != 0 else { return (0, sy / n) }
    let slope     = (n * sxy - sx * sy) / den
    let intercept = (sy - slope * sx) / n
    return (slope, intercept)
}

private func fmtK(_ n: Double) -> String {
    if n >= 1_000_000 { return String(format: "$%.2fM", n / 1_000_000) }
    if n >= 1_000     { return String(format: "$%.1fK", n / 1_000) }
    return "$\(Int(n))"
}

private func fmtPct(_ n: Double) -> String {
    (n >= 0 ? "+" : "") + String(format: "%.1f%%", n)
}

private func rankStr(_ i: Int) -> String {
    switch i {
    case 0: return "🥇"
    case 1: return "🥈"
    case 2: return "🥉"
    default: return "\(i + 1)"
    }
}

// MARK: - ForecastView

struct ForecastView: View {
    let customerStore: CustomerStore

    @State private var period    : FcstPeriod = .twelveM
    @State private var fwdWindow : FcstWindow = .six
    @State private var repFilter : String     = "All"

    // ── Source data ───────────────────────────────────────────────────────────

    private var allItems: [CustomerItem] { customerStore.items }

    private var reps: [String] {
        Set(allItems.compactMap { $0.salesman.isEmpty ? nil : $0.salesman }).sorted()
    }

    private var filtered: [CustomerItem] {
        repFilter == "All" ? allItems : allItems.filter { $0.salesman == repFilter }
    }

    private struct RevRec { let date: Date; let amount: Double; let salesman: String }

    private var revenueRecords: [RevRec] {
        filtered.compactMap { c in
            guard c.category.lowercased() == "customer",
                  c.amount > 0,
                  let d = revenueDate(c) else { return nil }
            return RevRec(date: d, amount: Double(c.amount), salesman: c.salesman)
        }
    }

    private var periodStart: Date? {
        let cal = Calendar.current
        let now = Date()
        let som = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        switch period {
        case .ytd:     return cal.date(from: cal.dateComponents([.year], from: now))
        case .sixM:    return cal.date(byAdding: .month, value: -5,  to: som)
        case .twelveM: return cal.date(byAdding: .month, value: -11, to: som)
        case .all:     return nil
        }
    }

    private var inPeriod: [RevRec] {
        guard let start = periodStart else { return revenueRecords }
        return revenueRecords.filter { $0.date >= start }
    }

    private var histKeys: [String] {
        switch period {
        case .ytd:     return lastNMonthKeys(Calendar.current.component(.month, from: Date()))
        case .sixM:    return lastNMonthKeys(6)
        case .twelveM: return lastNMonthKeys(12)
        case .all:     return lastNMonthKeys(24)
        }
    }

    private var historicalMap: [String: Double] {
        var m = [String: Double]()
        inPeriod.forEach { m[monthKey($0.date), default: 0] += $0.amount }
        return m
    }

    // ── Forecast ──────────────────────────────────────────────────────────────

    private var forecastRows: [FcstMonthRow]? {
        let keys    = lastNMonthKeys(12)
        let actuals: [(x: Double, y: Double)] = keys.enumerated().map { (i, k) in
            (x: Double(i), y: historicalMap[k] ?? 0)
        }
        let nonZero = actuals.filter { $0.y > 0 }
        guard nonZero.count >= 2 else { return nil }

        let (slope, intercept) = linReg(Array(nonZero.suffix(6)))
        let base = 12.0
        return nextNMonthKeys(fwdWindow.rawValue).enumerated().map { (i, k) in
            let raw = slope * (base + Double(i)) + intercept
            let p   = max(0, raw)
            return FcstMonthRow(label: monthLabel(k), projected: p,
                                low: max(0, p * 0.8), high: max(0, p * 1.2))
        }
    }

    // ── Chart arrays ─────────────────────────────────────────────────────────

    private var actualPoints: [FcstActualPoint] {
        histKeys.map { FcstActualPoint(label: monthLabel($0), value: historicalMap[$0] ?? 0) }
    }

    private var bandPoints: [FcstBandPoint] {
        (forecastRows ?? []).map { FcstBandPoint(label: $0.label, low: $0.low, high: $0.high) }
    }

    private var projPoints: [FcstProjPoint] {
        (forecastRows ?? []).map { FcstProjPoint(label: $0.label, value: $0.projected) }
    }

    private var dealsPoints: [FcstDealPoint] {
        var m = [String: Int]()
        inPeriod.forEach { m[monthKey($0.date), default: 0] += 1 }
        return histKeys.map { FcstDealPoint(label: monthLabel($0), count: m[$0] ?? 0) }
    }

    // ── KPIs ──────────────────────────────────────────────────────────────────

    private var totalActual    : Double { inPeriod.reduce(0) { $0 + $1.amount } }
    private var avgDeal        : Double { inPeriod.isEmpty ? 0 : totalActual / Double(inPeriod.count) }
    private var projectedTotal : Double { (forecastRows ?? []).reduce(0) { $0 + $1.projected } }
    private var pipelineTotal  : Double { pipelineRows.reduce(0) { $0 + $1.amount } }

    private var avgMonthly: Double {
        let count = histKeys.filter { (historicalMap[$0] ?? 0) > 0 }.count
        return count > 0 ? totalActual / Double(count) : 0
    }

    private var growthRate: Double? {
        let keys = histKeys.filter { (historicalMap[$0] ?? 0) > 0 }
        guard keys.count >= 4 else { return nil }
        let half   = keys.count / 2
        let first  = keys.prefix(half).reduce(0.0) { $0 + (historicalMap[$1] ?? 0) }
        let second = keys.dropFirst(half).reduce(0.0) { $0 + (historicalMap[$1] ?? 0) }
        guard first > 0 else { return nil }
        return (second - first) / first * 100
    }

    // ── Tables ────────────────────────────────────────────────────────────────

    private var byRep: [FcstRepRow] {
        var m = [String: (Double, Int)]()
        inPeriod.forEach { r in
            let rep = r.salesman.isEmpty ? "(unassigned)" : r.salesman
            let cur = m[rep] ?? (0, 0)
            m[rep] = (cur.0 + r.amount, cur.1 + 1)
        }
        return m.map { FcstRepRow(rep: $0.key, revenue: $0.value.0, deals: $0.value.1) }
            .sorted { $0.revenue > $1.revenue }
    }

    private var pipelineRows: [PipelineRow] {
        filtered
            .filter { $0.category.lowercased() == "lead" && $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
            .map {
                PipelineRow(cid: $0.id,
                            name: "\($0.first) \($0.lastname)".trimmingCharacters(in: .whitespaces),
                            salesman: $0.salesman,
                            amount: Double($0.amount))
            }
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controlsCard
                kpiGrid
                trendCard
                dealsCard
                byRepCard
                forecastTableCard
                if !pipelineRows.isEmpty { pipelineCard }
            }
            .padding(16)
        }
        .navigationTitle("Revenue Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }

    // ── Controls ──────────────────────────────────────────────────────────────

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Period picker
            HStack(spacing: 0) {
                ForEach(FcstPeriod.allCases, id: \.self) { p in
                    Button(p.rawValue) { period = p }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(period == p ? Color.indigo : Color.clear)
                        .foregroundStyle(period == p ? Color.white : Color.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))

            HStack(spacing: 12) {
                // Forecast window
                HStack(spacing: 0) {
                    ForEach(FcstWindow.allCases, id: \.self) { w in
                        Button(w.label) { fwdWindow = w }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(fwdWindow == w ? Color.purple : Color.clear)
                            .foregroundStyle(fwdWindow == w ? Color.white : Color.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))

                Spacer()

                // Rep filter
                Menu {
                    Button("All Reps") { repFilter = "All" }
                    ForEach(reps, id: \.self) { rep in
                        Button(rep) { repFilter = rep }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(repFilter == "All" ? "All Reps" : repFilter)
                            .font(.subheadline).lineLimit(1)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // ── KPI Grid ──────────────────────────────────────────────────────────────

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            FcstKpiCard(label: "Revenue (Period)",
                        value: fmtK(totalActual),
                        sub: "\(inPeriod.count) closed deal\(inPeriod.count == 1 ? "" : "s")",
                        color: .green)
            FcstKpiCard(label: "Avg Deal Size",
                        value: fmtK(avgDeal),
                        sub: "per closed deal",
                        color: .indigo)
            FcstKpiCard(label: "Monthly Avg",
                        value: fmtK(avgMonthly),
                        sub: growthRate.map { fmtPct($0) + " growth" } ?? "active months",
                        color: growthRate.map { $0 >= 0 ? Color.green : Color.red } ?? .secondary)
            FcstKpiCard(label: "\(fwdWindow.rawValue)-Mo Forecast",
                        value: fmtK(projectedTotal),
                        sub: "Pipeline: \(fmtK(pipelineTotal))",
                        color: .purple)
        }
    }

    // ── Revenue Trend Chart ───────────────────────────────────────────────────

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Revenue Trend & Forecast")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1).fill(Color.green)
                            .frame(width: 14, height: 3)
                        Text("Actual").font(.caption).foregroundStyle(Color.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1).fill(Color.purple)
                            .frame(width: 14, height: 3)
                        Text("Projected").font(.caption).foregroundStyle(Color.secondary)
                    }
                }
            }

            let hasData = actualPoints.contains { $0.value > 0 } || !projPoints.isEmpty
            if hasData {
                Chart {
                    // Draw actual area + line first so x-axis domain starts with historical months
                    ForEach(actualPoints) { p in
                        AreaMark(x: .value("Month", p.label), y: .value("Revenue", p.value))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.green.opacity(0.28), Color.green.opacity(0)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .interpolationMethod(.catmullRom)
                    }
                    ForEach(actualPoints) { p in
                        LineMark(x: .value("Month", p.label), y: .value("Revenue", p.value))
                            .foregroundStyle(Color.green)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                    }

                    // Confidence band
                    ForEach(bandPoints) { p in
                        AreaMark(x: .value("Month", p.label),
                                 yStart: .value("Low",  p.low),
                                 yEnd:   .value("High", p.high))
                            .foregroundStyle(Color.purple.opacity(0.12))
                            .interpolationMethod(.catmullRom)
                    }

                    // Projected line
                    ForEach(projPoints) { p in
                        LineMark(x: .value("Month", p.label), y: .value("Revenue", p.value))
                            .foregroundStyle(Color.purple)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                            .interpolationMethod(.catmullRom)
                    }
                }
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(fmtK(v)).font(.system(size: 9))
                            }
                        }
                    }
                }
                .frame(height: 220)

                if forecastRows != nil {
                    Text("Linear trend projection · ±20% confidence band")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Text("No revenue data in this period")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // ── Deals Per Month ───────────────────────────────────────────────────────

    private var dealsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deals Closed Per Month")
                .font(.subheadline.weight(.semibold))

            if dealsPoints.contains(where: { $0.count > 0 }) {
                Chart(dealsPoints) { d in
                    BarMark(x: .value("Month", d.label), y: .value("Deals", d.count))
                        .foregroundStyle(Color.indigo)
                        .cornerRadius(4)
                }
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.system(size: 8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)").font(.system(size: 9))
                            }
                        }
                    }
                }
                .frame(height: 130)
            } else {
                Text("No deals in this period")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // ── By Salesperson ────────────────────────────────────────────────────────

    private var byRepCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("By Salesperson")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            if byRep.isEmpty {
                Text("No revenue data")
                    .font(.subheadline).foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(20)
            } else {
                HStack {
                    Text("Rep")     .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Revenue") .frame(width: 72, alignment: .trailing)
                    Text("Deals")   .frame(width: 44, alignment: .trailing)
                    Text("Avg")     .frame(width: 64, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color(.tertiarySystemGroupedBackground))

                ForEach(Array(byRep.enumerated()), id: \.element.id) { idx, row in
                    Divider()
                    HStack {
                        HStack(spacing: 4) {
                            Text(rankStr(idx)).font(.caption)
                            Text(row.rep).font(.subheadline).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(fmtK(row.revenue))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.green)
                            .frame(width: 72, alignment: .trailing)
                        Text("\(row.deals)")
                            .font(.subheadline).foregroundStyle(Color.secondary)
                            .frame(width: 44, alignment: .trailing)
                        Text(fmtK(row.avg))
                            .font(.caption).foregroundStyle(Color.secondary)
                            .frame(width: 64, alignment: .trailing)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // ── Forecast Table ────────────────────────────────────────────────────────

    private var forecastTableCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Monthly Forecast (+\(fwdWindow.rawValue) months)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            if let rows = forecastRows {
                HStack {
                    Text("Month")     .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Low")       .frame(width: 60, alignment: .trailing)
                    Text("Projected") .frame(width: 72, alignment: .trailing)
                    Text("High")      .frame(width: 60, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Color(.tertiarySystemGroupedBackground))

                ForEach(rows) { row in
                    Divider()
                    HStack {
                        Text(row.label)
                            .font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                        Text(fmtK(row.low))
                            .font(.caption).foregroundStyle(Color.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Text(fmtK(row.projected))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Color.purple)
                            .frame(width: 72, alignment: .trailing)
                        Text(fmtK(row.high))
                            .font(.caption).foregroundStyle(Color.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                }

                // Totals row
                let totalLow  = rows.reduce(0.0) { $0 + $1.low }
                let totalHigh = rows.reduce(0.0) { $0 + $1.high }
                Divider()
                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                    Text(fmtK(totalLow))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.secondary)
                        .frame(width: 60, alignment: .trailing)
                    Text(fmtK(projectedTotal))
                        .font(.subheadline.weight(.bold)).foregroundStyle(Color.purple)
                        .frame(width: 72, alignment: .trailing)
                    Text(fmtK(totalHigh))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Color(.tertiarySystemGroupedBackground))

            } else {
                Text("Need at least 2 months of data to generate a forecast")
                    .font(.subheadline).foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center).padding(24)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // ── Pipeline ──────────────────────────────────────────────────────────────

    private var pipelineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pipeline — Open Leads with Est. Value")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(fmtK(pipelineTotal))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.indigo)
            }

            let top    = Array(pipelineRows.prefix(10))
            let maxAmt = top.first?.amount ?? 1

            ForEach(top) { row in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.name).font(.subheadline).lineLimit(1)
                        if !row.salesman.isEmpty {
                            Text(row.salesman).font(.caption).foregroundStyle(Color.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(fmtK(row.amount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.indigo)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.indigo)
                                    .frame(width: geo.size.width * (row.amount / maxAmt))
                            }
                    }
                    .frame(width: 72, height: 6)
                }
            }

            if pipelineRows.count > 10 {
                Text("+ \(pipelineRows.count - 10) more leads in pipeline")
                    .font(.caption).foregroundStyle(Color.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - KPI Card

private struct FcstKpiCard: View {
    let label : String
    let value : String
    let sub   : String
    let color : Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
