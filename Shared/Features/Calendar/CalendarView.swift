//
//  CalendarView.swift
//  TheLightUI
//

import SwiftUI

// MARK: - Event Type

private enum CalEventType: String, CaseIterable {
    case appt        = "appt"
    case jobStart    = "job-start"
    case jobComplete = "job-complete"
    case followup    = "followup"

    var label: String {
        switch self {
        case .appt:        return "Appointment"
        case .jobStart:    return "Job Start"
        case .jobComplete: return "Job Done"
        case .followup:    return "Follow-up"
        }
    }

    var color: Color {
        switch self {
        case .appt:        return .indigo
        case .jobStart:    return .teal
        case .jobComplete: return .green
        case .followup:    return .red
        }
    }

    var icon: String {
        switch self {
        case .appt:        return "calendar"
        case .jobStart:    return "hammer.fill"
        case .jobComplete: return "checkmark.circle.fill"
        case .followup:    return "bell.fill"
        }
    }
}

// MARK: - Cal Event

private struct CalEvent: Identifiable {
    let id: String
    let type: CalEventType
    let date: Date
    let name: String
    let sub: String?       // optional subtitle (e.g. task priority, service plan title)
    let salesman: String
    let customer: CustomerItem
}

// MARK: - View Mode

private enum CalViewMode: String, CaseIterable {
    case month = "Month"
    case week  = "Week"
    case list  = "List"
}

// MARK: - Helpers

private let calHelper = Calendar.current
private let weekdayAbbs = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

private func calDateKey(_ d: Date) -> String {
    let c = calHelper.dateComponents([.year, .month, .day], from: d)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
}

private func isValidEventDate(_ d: Date) -> Bool {
    d.timeIntervalSince1970 > 86_400
}

private func buildMonthDays(for anchor: Date) -> [Date] {
    guard let first = calHelper.date(from: calHelper.dateComponents([.year, .month], from: anchor)) else { return [] }
    let firstWeekday = calHelper.component(.weekday, from: first) - 1
    let count = calHelper.range(of: .day, in: .month, for: first)?.count ?? 30
    var days: [Date] = []
    for i in stride(from: firstWeekday, through: 1, by: -1) {
        if let d = calHelper.date(byAdding: .day, value: -i, to: first) { days.append(d) }
    }
    for i in 0..<count {
        if let d = calHelper.date(byAdding: .day, value: i, to: first) { days.append(d) }
    }
    if let nextMonth = calHelper.date(byAdding: .month, value: 1, to: first) {
        var i = 0
        while days.count < 42, i < 14 {
            if let d = calHelper.date(byAdding: .day, value: i, to: nextMonth) { days.append(d) }
            i += 1
        }
    }
    return days
}

private func buildWeekDays(anchor: Date) -> [Date] {
    let weekday = calHelper.component(.weekday, from: anchor) - 1
    guard let start = calHelper.date(byAdding: .day, value: -weekday, to: anchor) else { return [] }
    return (0..<7).compactMap { calHelper.date(byAdding: .day, value: $0, to: start) }
}

// MARK: - CalendarView

@MainActor
struct CalendarView: View {
    let customerStore: CustomerStore

    @State private var viewMode: CalViewMode = .month
    @State private var filterType: CalEventType?
    @State private var repFilter = ""
    @State private var viewDate: Date
    @State private var selectedKey: String
    @State private var pickerModel = PickerDataModel()

    private static let todayKey = calDateKey(Date())

    init(customerStore: CustomerStore) {
        self.customerStore = customerStore
        let now = Date()
        let monthStart = calHelper.date(from: calHelper.dateComponents([.year, .month], from: now)) ?? now
        _viewDate    = State(initialValue: monthStart)
        _selectedKey = State(initialValue: calDateKey(now))
    }

    // MARK: - Derived data

    private var reps: [String] {
        Set(customerStore.items.compactMap { $0.salesman.isEmpty ? nil : $0.salesman }).sorted()
    }

    private var allEventMap: [String: [CalEvent]] {
        var map: [String: [CalEvent]] = [:]

        func add(_ id: String, _ type: CalEventType, _ date: Date, _ c: CustomerItem, sub: String? = nil) {
            guard isValidEventDate(date) else { return }
            let nameParts = [c.first, c.lastname].filter { !$0.isEmpty }
            let name = nameParts.isEmpty ? "—" : nameParts.joined(separator: " ")
            let event = CalEvent(id: id, type: type, date: date, name: name, sub: sub, salesman: c.salesman, customer: c)
            map[calDateKey(date), default: []].append(event)
        }

        for c in customerStore.items {
            // Appointments and job events only show for active records
            if c.isActive {
                if CustomerItem.Category.lead.matches(c.category) {
                    add("appt-\(c.id)", .appt, c.startDate, c)
                }
                if CustomerItem.Category.customer.matches(c.category) {
                    add("job-start-\(c.id)", .jobStart, c.startDate, c)
                    if isValidEventDate(c.completionDate),
                       !calHelper.isDate(c.completionDate, inSameDayAs: c.startDate) {
                        add("job-done-\(c.id)", .jobComplete, c.completionDate, c)
                    }
                }
            }
            // Follow-ups show regardless of active status (matches web behavior)
            if let fu = c.followUpDate {
                add("fu-\(c.id)", .followup, fu, c)
            }
        }

        let priority: [CalEventType] = [.followup, .appt, .jobStart, .jobComplete]
        for key in map.keys {
            map[key]?.sort {
                (priority.firstIndex(of: $0.type) ?? 99) < (priority.firstIndex(of: $1.type) ?? 99)
            }
        }
        return map
    }

    private var eventMap: [String: [CalEvent]] {
        guard !repFilter.isEmpty else { return allEventMap }
        var result: [String: [CalEvent]] = [:]
        for (key, events) in allEventMap {
            // Show events with no salesman + events matching the rep filter (matches web behavior)
            let f = events.filter { $0.salesman.isEmpty || $0.salesman == repFilter }
            if !f.isEmpty { result[key] = f }
        }
        return result
    }

    private func eventsForKey(_ key: String) -> [CalEvent] {
        let all = eventMap[key] ?? []
        guard let f = filterType else { return all }
        return all.filter { $0.type == f }
    }

    private var typeCounts: [CalEventType: Int] {
        var counts: [CalEventType: Int] = [:]
        for events in eventMap.values {
            for e in events { counts[e.type, default: 0] += 1 }
        }
        return counts
    }

    private var monthDays: [Date] { buildMonthDays(for: viewDate) }
    private var currentWeekDays: [Date] { buildWeekDays(anchor: viewDate) }

    private var periodLabel: String {
        if viewMode == .week {
            guard let ws = currentWeekDays.first, let we = currentWeekDays.last else { return "" }
            let fmt1 = DateFormatter(); fmt1.dateFormat = "MMM d"
            let fmt2 = DateFormatter(); fmt2.dateFormat = "MMM d, yyyy"
            return "\(fmt1.string(from: ws)) – \(fmt2.string(from: we))"
        }
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: viewDate)
    }

    private var selectedDayLabel: String {
        let parts = selectedKey.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              let date = calHelper.date(from: DateComponents(year: y, month: m, day: d)) else { return "" }
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: date)
    }

    private var upcomingGroups: [(label: String, events: [CalEvent])] {
        let today = calHelper.startOfDay(for: Date())
        var all: [CalEvent] = []
        for events in eventMap.values {
            for e in events {
                guard e.date >= today else { continue }
                if let f = filterType, e.type != f { continue }
                all.append(e)
            }
        }
        all.sort { $0.date < $1.date }

        var groups: [(label: String, events: [CalEvent])] = []
        var batchKey = ""
        var batchLabel = ""
        var batch: [CalEvent] = []

        for e in all {
            let key = calDateKey(e.date)
            if key != batchKey {
                if !batch.isEmpty { groups.append((batchLabel, batch)) }
                batchKey   = key
                batchLabel = dayLabel(e.date)
                batch      = [e]
            } else {
                batch.append(e)
            }
        }
        if !batch.isEmpty { groups.append((batchLabel, batch)) }
        return Array(groups.prefix(60))
    }

    private func dayLabel(_ d: Date) -> String {
        if calHelper.isDateInToday(d)     { return "Today" }
        if calHelper.isDateInTomorrow(d)  { return "Tomorrow" }
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: d)
    }

    // MARK: - Navigation

    private func prevPeriod() {
        viewDate = (viewMode == .week
            ? calHelper.date(byAdding: .day, value: -7, to: viewDate)
            : calHelper.date(byAdding: .month, value: -1, to: viewDate)) ?? viewDate
    }

    private func nextPeriod() {
        viewDate = (viewMode == .week
            ? calHelper.date(byAdding: .day, value: 7, to: viewDate)
            : calHelper.date(byAdding: .month, value: 1, to: viewDate)) ?? viewDate
    }

    private func goToday() {
        viewDate    = calHelper.date(from: calHelper.dateComponents([.year, .month], from: Date())) ?? Date()
        selectedKey = Self.todayKey
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                headerControls
                filterChips
                if customerStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else {
                    switch viewMode {
                    case .month:
                        monthGrid
                        selectedDayPanel
                    case .week:
                        weekGrid
                    case .list:
                        listContent
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CustomerItem.self) { item in
            LeadDetailUI(detail: item)
                .environment(pickerModel)
                .environment(customerStore)
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Header

    private var headerControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Mode picker
                HStack(spacing: 2) {
                    ForEach(CalViewMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            withAnimation(.easeInOut(duration: 0.15)) { viewMode = mode }
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewMode == mode ? Color.accentColor : Color.clear)
                        .foregroundStyle(viewMode == mode ? Color.white : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                if viewMode != .list {
                    // Prev / Label / Next / Today
                    Button { prevPeriod() } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    Text(periodLabel)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Button { nextPeriod() } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    Button("Today") { goToday() }
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }

                if !reps.isEmpty {
                    repMenu
                }
            }
        }
    }

    private var repMenu: some View {
        Menu {
            Button { repFilter = "" } label: {
                Label("All Reps", systemImage: repFilter.isEmpty ? "checkmark" : "person.2")
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

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(label: "All", dotColor: nil, selected: filterType == nil) {
                    filterType = nil
                }
                ForEach(CalEventType.allCases, id: \.self) { type in
                    let count = typeCounts[type] ?? 0
                    if count > 0 {
                        filterChip(
                            label: "\(type.label) (\(count))",
                            dotColor: type.color,
                            selected: filterType == type
                        ) {
                            filterType = filterType == type ? nil : type
                        }
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func filterChip(label: String, dotColor: Color?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let dc = dotColor {
                    Circle().fill(dc).frame(width: 6, height: 6)
                }
                Text(label).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(selected ? Color.white : Color.secondary)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5))
        }
    }

    // MARK: - Month Grid

    @ViewBuilder
    private var monthGrid: some View {
        let days = monthDays
        let curMonth = calHelper.component(.month, from: viewDate)

        VStack(spacing: 0) {
            // Weekday header row
            HStack(spacing: 0) {
                ForEach(weekdayAbbs, id: \.self) { d in
                    Text(d)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
            }
            Divider()

            // Day grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 0
            ) {
                ForEach(days.indices, id: \.self) { i in
                    let day = days[i]
                    let key = calDateKey(day)
                    let inMonth   = calHelper.component(.month, from: day) == curMonth
                    let isToday   = key == Self.todayKey
                    let isSel     = key == selectedKey
                    let dayEvents = eventMap[key] ?? []

                    Button { selectedKey = key } label: {
                        VStack(spacing: 2) {
                            ZStack {
                                if isToday {
                                    Circle().fill(Color.accentColor).frame(width: 24, height: 24)
                                } else if isSel {
                                    Circle().fill(Color(.systemGray4)).frame(width: 24, height: 24)
                                }
                                Text("\(calHelper.component(.day, from: day))")
                                    .font(.caption.weight(isToday ? .bold : .regular))
                                    .foregroundStyle(
                                        isToday   ? Color.white :
                                        inMonth   ? Color.primary :
                                        Color.secondary.opacity(0.4)
                                    )
                            }
                            HStack(spacing: 2) {
                                ForEach(dayEvents.prefix(3)) { e in
                                    Circle().fill(e.type.color).frame(width: 4, height: 4)
                                }
                                if dayEvents.count > 3 {
                                    Text("+").font(.system(size: 7)).foregroundStyle(Color.secondary)
                                }
                            }
                            .frame(height: 6)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(isSel && !isToday ? Color.accentColor.opacity(0.09) : Color.clear)
                        .overlay(alignment: .bottom) {
                            Divider().opacity(0.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Selected Day Panel

    @ViewBuilder
    private var selectedDayPanel: some View {
        let selEvents = eventsForKey(selectedKey)
        let allForDay = eventMap[selectedKey] ?? []

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedDayLabel)
                    .font(.subheadline.weight(.semibold))
                if !allForDay.isEmpty {
                    let label = filterType != nil ? "\(selEvents.count)/\(allForDay.count)" : "\(selEvents.count)"
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            if selEvents.isEmpty {
                let msg = allForDay.isEmpty ? "No events on this day" : "No matching events — try \"All\""
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                eventList(selEvents)
            }
        }
    }

    // MARK: - Week Grid

    @ViewBuilder
    private var weekGrid: some View {
        let wDays = currentWeekDays

        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(wDays.indices, id: \.self) { i in
                    let day = wDays[i]
                    let isToday = calHelper.isDateInToday(day)
                    VStack(spacing: 2) {
                        Text(weekdayAbbs[calHelper.component(.weekday, from: day) - 1])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        ZStack {
                            if isToday {
                                Circle().fill(Color.accentColor).frame(width: 26, height: 26)
                            }
                            Text("\(calHelper.component(.day, from: day))")
                                .font(.caption.weight(isToday ? .bold : .medium))
                                .foregroundStyle(isToday ? Color.white : Color.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    if i < wDays.count - 1 { Divider().frame(maxHeight: 44) }
                }
            }
            Divider()

            // Event columns
            HStack(alignment: .top, spacing: 0) {
                ForEach(wDays.indices, id: \.self) { i in
                    let day = wDays[i]
                    let dayEvents = eventsForKey(calDateKey(day))
                    VStack(spacing: 3) {
                        ForEach(dayEvents) { event in
                            NavigationLink(value: event.customer) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(event.name)
                                        .font(.system(size: 9, weight: .semibold))
                                        .lineLimit(2)
                                    Text(event.sub ?? event.type.label)
                                        .font(.system(size: 8))
                                        .opacity(0.8)
                                    if !event.salesman.isEmpty {
                                        Text(event.salesman)
                                            .font(.system(size: 8))
                                            .opacity(0.6)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(event.type.color.opacity(0.15))
                                .foregroundStyle(event.type.color)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .top)
                    .padding(4)
                    if i < wDays.count - 1 { Divider() }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        let groups = upcomingGroups
        if groups.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.secondary)
                Text("No upcoming events")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
                Text("Events come from lead appointments,\njob dates, and follow-up reminders.")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            VStack(spacing: 14) {
                ForEach(groups, id: \.label) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                            .textCase(.uppercase)
                        eventList(group.events)
                    }
                }
            }
        }
    }

    // MARK: - Shared event list

    @ViewBuilder
    private func eventList(_ events: [CalEvent]) -> some View {
        VStack(spacing: 0) {
            ForEach(events.indices, id: \.self) { i in
                NavigationLink(value: events[i].customer) {
                    CalEventRow(event: events[i])
                }
                .buttonStyle(.plain)
                if i < events.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Event Row

private struct CalEventRow: View {
    let event: CalEvent

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: event.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(event.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if !event.salesman.isEmpty {
                        Text(event.salesman)
                            .foregroundStyle(Color.secondary)
                        Text("·")
                            .foregroundStyle(Color(.separator))
                    }
                    Text(event.sub ?? event.type.label)
                        .foregroundStyle(event.type.color)
                }
                .font(.caption)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
