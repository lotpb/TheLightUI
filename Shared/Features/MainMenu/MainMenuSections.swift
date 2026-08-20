//
//  MainMenuSections.swift
//  TheLightUI
//

import SwiftUI

// MARK: - Shared Section Header

private struct MenuSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
            .foregroundStyle(.primary)
            .padding(.top, 4)
    }
}

// MARK: - Shared Grid Card

private struct MenuGridCard: View {
    @AppStorage(SettingsUI.useThemeMenuIconsKey) private var useThemeMenuIcons = false
    @AppStorage(SettingsUI.color) private var themeColorSetting: Int?

    let title: String
    let subtitle: String
    let systemImage: String
    let iconColor: Color
    let action: () -> Void

    private var resolvedColor: Color {
        useThemeMenuIcons ? AppTheme.accentColor(for: themeColorSetting) : iconColor
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(resolvedColor.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: resolvedColor.opacity(0.4), radius: 5, x: 0, y: 3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Row helper

private struct MenuGridSection<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            content
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Analytics Section

struct AnalyticsSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    private struct Item: Identifiable {
        let id: MainMenuDataRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let iconColor: Color
    }

    private let items: [Item] = [
        Item(id: .snapshot, title: "Snapshot",  subtitle: "Live overview",       systemImage: "camera.viewfinder",    iconColor: .green),
        Item(id: .chart,    title: "Chart",     subtitle: "Visualize data",      systemImage: "chart.bar.fill",       iconColor: .purple),
        Item(id: .calendar, title: "Calendar",  subtitle: "Events & schedule",   systemImage: "calendar.badge.clock", iconColor: .orange),
        Item(id: .heatmap,  title: "Heat Map",  subtitle: "Geographic density",  systemImage: "map.fill",                      iconColor: .red),
        Item(id: .reports,   title: "Reports",   subtitle: "Performance & trends",  systemImage: "doc.text.magnifyingglass",    iconColor: .cyan),
        Item(id: .forecast,  title: "Forecast",  subtitle: "Revenue projection",    systemImage: "chart.line.uptrend.xyaxis",   iconColor: .teal),
    ]

    var body: some View {
        Section {
            MenuGridSection {
                ForEach(items) { item in
                    MenuGridCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconColor: item.iconColor
                    ) { onSelect(item.id) }
                }
            }
        } header: {
            MenuSectionHeader(title: "Analytics")
        }
    }
}

// MARK: - CRM Section

struct CRMSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    private struct Item: Identifiable {
        let id: MainMenuDataRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let iconColor: Color
    }

    private let items: [Item] = [
        Item(id: .leads,     title: "Leads",     subtitle: "Potential customers",  systemImage: "person.crop.circle.badge.plus", iconColor: .blue),
        Item(id: .customers, title: "Customers", subtitle: "Active accounts",      systemImage: "person.2.fill",                 iconColor: .indigo),
        Item(id: .vendors,   title: "Vendors",   subtitle: "Suppliers & partners", systemImage: "shippingbox.fill",              iconColor: .brown),
        Item(id: .employee,  title: "Employee",  subtitle: "Team directory",       systemImage: "person.text.rectangle",         iconColor: .teal),
    ]

    var body: some View {
        Section {
            MenuGridSection {
                ForEach(items) { item in
                    MenuGridCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconColor: item.iconColor
                    ) { onSelect(item.id) }
                }
            }
        } header: {
            MenuSectionHeader(title: "CRM")
        }
    }
}

// MARK: - Communication Section

struct CommunicationSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    private struct Item: Identifiable {
        let id: MainMenuFullscreenRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let iconColor: Color
    }

    private let items: [Item] = [
        Item(id: .chat, title: "Chat", subtitle: "Messages & conversations", systemImage: "bubble.left.and.bubble.right.fill", iconColor: .green),
    ]

    var body: some View {
        Section {
            MenuGridSection {
                ForEach(items) { item in
                    MenuGridCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconColor: item.iconColor
                    ) { onSelectRoute(item.id) }
                }
            }
        } header: {
            MenuSectionHeader(title: "Communication")
        }
    }
}

// MARK: - Tools Section

struct ToolsSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    private struct Item: Identifiable {
        let id: MainMenuDataRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let iconColor: Color
    }

    private let items: [Item] = [
        Item(id: .todo,     title: "To Do",          subtitle: "Tasks and reminders",  systemImage: "checklist",               iconColor: .purple),
        Item(id: .expenses, title: "Expenses",       subtitle: "Track spending",        systemImage: "creditcard.fill",         iconColor: .green),
        Item(id: .tip,      title: "Tip Calculator", subtitle: "Split a bill",          systemImage: "receipt.fill",            iconColor: .orange),
        Item(id: .steps,    title: "Steps Today",    subtitle: "Count today's steps",   systemImage: "figure.walk.circle.fill", iconColor: .red),
    ]

    var body: some View {
        Section {
            MenuGridSection {
                ForEach(items) { item in
                    MenuGridCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconColor: item.iconColor
                    ) { onSelect(item.id) }
                }
            }
        } header: {
            MenuSectionHeader(title: "Tools")
        }
    }
}

// MARK: - Explore Section

struct ExploreSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    private struct Item: Identifiable {
        let id: MainMenuFullscreenRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let iconColor: Color
    }

    private let items: [Item] = [
        Item(id: .geotify,   title: "Geotify",       subtitle: "Region monitoring",     systemImage: "mappin.and.ellipse",         iconColor: .red),
        Item(id: .places,    title: "Search Places", subtitle: "Find a place nearby",   systemImage: "magnifyingglass.circle.fill", iconColor: .mint),
        Item(id: .weather,   title: "Weather",       subtitle: "Forecast & conditions", systemImage: "cloud.sun.fill",              iconColor: .cyan),
        Item(id: .instagram, title: "Instagram",     subtitle: "Photo feed viewer",     systemImage: "camera.fill",                iconColor: .pink),
        Item(id: .tweet,     title: "Twitter",       subtitle: "Timeline viewer",       systemImage: "bird.fill",                  iconColor: Color(red: 0.11, green: 0.63, blue: 0.95)),
        Item(id: .stacks,    title: "Stacks",        subtitle: "Layout demos",          systemImage: "square.stack.3d.up.fill",    iconColor: .gray),
    ]

    var body: some View {
        Section {
            MenuGridSection {
                ForEach(items) { item in
                    MenuGridCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconColor: item.iconColor
                    ) { onSelectRoute(item.id) }
                }
            }
        } header: {
            MenuSectionHeader(title: "Explore")
        }
    }
}

#Preview {
    List {
        AnalyticsSection(themeColor: .blue) { _ in }
        CRMSection(themeColor: .blue) { _ in }
        CommunicationSection(themeColor: .blue) { _ in }
        ToolsSection(themeColor: .blue) { _ in }
        ExploreSection(themeColor: .blue) { _ in }
    }
    .listStyle(.insetGrouped)
}
