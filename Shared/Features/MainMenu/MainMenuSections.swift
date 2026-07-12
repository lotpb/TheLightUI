//
//  MainMenuSections.swift
//  TheLightUI
//

import SwiftUI

struct IncomingSection: View {
    let themeColor: Color
    private let menuItems = ["Snapshot", "Statistics"]

    var body: some View {
        Section {
            ForEach(menuItems, id: \.self) { message in
                NavigationLink {
                    incomingDestination(for: message)
                } label: {
                    incomingLabel(message)
                }
            }
        } header: {
            Text("Incoming").foregroundStyle(themeColor)
        }
    }

    @ViewBuilder
    private func incomingDestination(for message: String) -> some View {
        switch message {
        case "Statistics":
            iMacUI()
        default:
            MacbookPro()
        }
    }

    private func incomingLabel(_ message: String) -> some View {
        Label(message, systemImage: "message")
            .badge("NEW ITEMS!")
            .listItemTint(themeColor)
    }
}

struct DataSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    private var items: [DataMenuItem] {
        var items: [DataMenuItem] = [
            DataMenuItem(
                route: .leads,
                title: "Leads",
                subtitle: "Potential customers",
                systemImage: "person.crop.circle.badge.plus",
                iconColor: .blue
            ),
            DataMenuItem(
                route: .customers,
                title: "Customers",
                subtitle: "Active accounts",
                systemImage: "person.2.fill",
                iconColor: .indigo
            )
        ]

        #if DEBUG
        items.append(contentsOf: [
            DataMenuItem(
                route: .vendors,
                title: "Vendors",
                subtitle: "Suppliers",
                systemImage: "shippingbox.fill",
                iconColor: .brown
            ),
            DataMenuItem(
                route: .employee,
                title: "Employee",
                subtitle: "Team directory",
                systemImage: "person.text.rectangle",
                iconColor: .teal
            )
        ])
        #endif

        return items
    }

    var body: some View {
        Section {
            ForEach(items) { item in
                MenuRouteButton(item: item) {
                    onSelect(item.route)
                }
            }
        } header: {
            Text("Data").foregroundStyle(themeColor)
        }
    }
}

struct AppsSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    private let items: [DataMenuItem] = [
        DataMenuItem(
            route: .expenses,
            title: "Expenses",
            subtitle: "Track spending",
            systemImage: "creditcard.fill",
            iconColor: .green
        ),
        DataMenuItem(
            route: .tip,
            title: "Tip Calculator",
            subtitle: "Split a bill",
            systemImage: "receipt.fill",
            iconColor: .orange
        ),
        DataMenuItem(
            route: .steps,
            title: "Steps Today",
            subtitle: "Count today's steps",
            systemImage: "figure.walk.circle.fill",
            iconColor: .red
        )
    ]

    private var socialItems: [FullscreenMenuItem] {
        #if DEBUG
        [
            FullscreenMenuItem(
                route: .instagram,
                title: "Instagram",
                subtitle: "Social feed",
                systemImage: "camera.circle.fill",
                iconColor: .pink
            ),
            FullscreenMenuItem(
                route: .tweet,
                title: "Twitter",
                subtitle: "Social feed",
                systemImage: "text.bubble.fill",
                iconColor: .blue
            )
        ]
        #else
        []
        #endif
    }

    var body: some View {
        Section {
            ForEach(items) { item in
                MenuRouteButton(item: item) {
                    onSelect(item.route)
                }
            }
            ForEach(socialItems) { item in
                MenuRouteButton(item: item) {
                    onSelectRoute(item.route)
                }
            }
        } header: {
            Text("Apps").foregroundStyle(themeColor)
        }
    }
}

struct ExploreSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    private var items: [FullscreenMenuItem] {
        var items: [FullscreenMenuItem] = [
            FullscreenMenuItem(
                route: .geotify,
                title: "Geotify",
                subtitle: "Region monitoring",
                systemImage: "mappin.and.ellipse",
                iconColor: .red
            ),
            FullscreenMenuItem(
                route: .places,
                title: "Search Places",
                subtitle: "Find a place nearby",
                systemImage: "magnifyingglass.circle.fill",
                iconColor: .mint
            ),
            FullscreenMenuItem(
                route: .weather,
                title: "Weather",
                subtitle: "Forecast and conditions",
                systemImage: "cloud.sun.fill",
                iconColor: .cyan
            )
        ]

        #if DEBUG
        items.insert(
            FullscreenMenuItem(
                route: .chart,
                title: "Chart",
                subtitle: "Analytics",
                systemImage: "chart.bar.fill",
                iconColor: .purple
            ),
            at: 0
        )
        items.append(
            FullscreenMenuItem(
                route: .stacks,
                title: "Stacks",
                subtitle: "Layout demos",
                systemImage: "square.stack.3d.up.fill",
                iconColor: .gray
            )
        )
        #endif

        return items
    }

    var body: some View {
        Section {
            ForEach(items) { item in
                MenuRouteButton(item: item) {
                    onSelectRoute(item.route)
                }
            }
        } header: {
            Text("Explore").foregroundStyle(themeColor)
        }
    }
}

private struct DataMenuItem: Identifiable, MenuRouteDisplaying {
    let route: MainMenuDataRoute
    let title: String
    let subtitle: String?
    let systemImage: String
    let iconColor: Color

    var id: MainMenuDataRoute { route }
}

private struct FullscreenMenuItem: Identifiable, MenuRouteDisplaying {
    let route: MainMenuFullscreenRoute
    let title: String
    let subtitle: String?
    let systemImage: String
    let iconColor: Color

    var id: MainMenuFullscreenRoute { route }
}

#Preview {
    List {
        DataSection(themeColor: .blue) { _ in }
        ExploreSection(themeColor: .blue) { _ in }
        AppsSection(
            themeColor: .blue,
            onSelect: { _ in },
            onSelectRoute: { _ in }
        )
    }
    .listStyle(.insetGrouped)
}
