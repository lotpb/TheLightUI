//
//  ContentView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import UIKit

// MARK: - Root Content
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var session: SessionViewModel
    @State private var selection: RootTab = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var tabBarHeight: CGFloat = 0

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _session = State(
            initialValue: SessionViewModel(sessionService: dependencies.sessionService)
        )
    }
    
    var body: some View {
        rootLayout
            .fullScreenCover(isPresented: $session.isLoginPresented) {
                LoginView(
                    loginService: dependencies.makeLoginService(),
                    authenticationService: dependencies.makeAuthenticationService(),
                    locationCaptureManager: dependencies.makeLocationCaptureManager(),
                    didCompleteLoginProcess: session.handleLoginCompleted
                )
            }
    }

    // Sidebar on full-width iPad; custom tab bar on iPhone and in compact
    // iPad multitasking widths.
    @ViewBuilder
    private var rootLayout: some View {
        if usesSidebar {
            sidebarLayout
        } else {
            tabBarLayout
        }
    }

    // Pro Max iPhones report a regular width in landscape, so also require
    // the pad idiom before swapping the tab bar for a sidebar.
    private var usesSidebar: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular
    }

    private var sidebarLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: sidebarSelection) {
                ForEach(RootTab.visibleTabs) { tab in
                    Label(tab.label, systemImage: tab.image)
                        .tag(tab)
                }
            }
            .navigationTitle("TheLight")
            .navigationSplitViewColumnWidth(225)
        } detail: {
            selectedTabContent
        }
    }

    /// Adapts the non-optional tab selection to the optional binding that
    /// sidebar `List` selection requires, ignoring deselection.
    private var sidebarSelection: Binding<RootTab?> {
        Binding(
            get: { selection },
            set: { newValue in
                if let newValue {
                    selection = newValue
                }
            }
        )
    }

    // The bar contributes a real safe-area inset so most screens clear it
    // automatically. NavigationStack does not forward that inset to the
    // scroll insets of Lists inside it, so the measured bar height is also
    // published through the environment for those screens to re-apply.
    private var tabBarLayout: some View {
        tabContent
            .environment(\.tabBarOverlap, tabBarHeight)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    TabBarView(selection: $selection)
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    tabBarHeight = height
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        selectedTabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selection {
        case .home:
            MainMenuUI(
                onSignOut: session.signOut,
                makeCustomerService: dependencies.makeCustomerService,
                makeCustomerFormService: dependencies.makeCustomerFormService,
                makeWeatherManager: dependencies.makeWeatherManager,
                makeWeatherLocationProvider: dependencies.makeWeatherLocationProvider,
                appBadgeManager: dependencies.appBadgeManager
            )
        case .chat:
            MainMessagesView(
                isAuthenticated: session.isAuthenticated,
                onSignOut: session.signOut,
                repository: dependencies.makeChatRepository(),
                chatLogRepository: dependencies.makeChatRepository(),
                makeChatRepository: dependencies.makeChatRepository
            )
        case .ToDo:
            // ListView's toolbar (edit, import/export menu, add) needs a
            // navigation bar to render in.
            NavigationStack {
                ListView()
            }
        case .Expense:
            if #available(iOS 18.0, *) {
                NavigationStack {
                    ExpenseTrackerView()
                }
                .expenseModelContainer()
            } else {
                Text("Requires iOS 18")
            }
        case .tip:
            TipUI()
        case .web:
            // Collapse the iPad sidebar when a bookmark's web page opens so
            // the page gets the full width; no-op in the tab bar layout.
            WebUI(onOpenPage: {
                withAnimation {
                    columnVisibility = .detailOnly
                }
            })
        }
    }
}

// MARK: - Tab Bar Overlap
extension EnvironmentValues {
    /// Height of the custom bottom tab bar overlapping the tab content.
    /// Screens that host a `List` inside their own `NavigationStack` read
    /// this to reserve bottom space, because the bar's outer safe-area inset
    /// stops at the stack boundary. Zero in the sidebar layout and previews.
    @Entry var tabBarOverlap: CGFloat = 0
}

// MARK: - Root Tabs
private enum RootTab: CaseIterable, Identifiable {
    case home
    case chat
    case ToDo
    case Expense
    case tip
    case web

    static var visibleTabs: [RootTab] {
        #if DEBUG
        return allCases
        #else
        return [.home, .chat, .ToDo]
        #endif
    }

    var id: Self { self }

    var image: String {
        switch self {
        case .home: return "house.fill"
        case .chat: return "message.fill"
        case .ToDo: return "wave.3.left"
        case .Expense: return "dollarsign.circle"
        case .tip: return "percent"
        case .web: return "network"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chat"
        case .ToDo: return "To Do"
        case .Expense: return "Expense"
        case .tip: return "Tip"
        case .web: return "Web"
        }
    }
}

// MARK: - Tab Bar
private struct TabBarView: View {
    @Binding var selection: RootTab
    @Namespace private var currentTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.visibleTabs) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selection == tab,
                    namespace: currentTab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = tab
                    }
                }
            }
        }
        // Cap the tab row so items stay grouped on wide iPad screens; the
        // material background still spans the full width below.
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 6, leading: 8, bottom: 8, trailing: 8))
        .background(.ultraThinMaterial)
    }
}

private struct TabBarItem: View {
    let tab: RootTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                selectionIndicator

                Image(systemName: tab.image)
                    .font(.caption)
                    .frame(height: 18)

                Text(tab.label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Capsule()
                .fill(Color.primary)
                .matchedGeometryEffect(id: "currentTab", in: namespace)
                .frame(width: 24, height: 3)
        } else {
            Capsule()
                .fill(Color.clear)
                .frame(width: 24, height: 3)
        }
    }
}

// MARK: - Previews
#Preview("Content - Dark") {
    ContentView(dependencies: .preview)
        .preferredColorScheme(.dark)
}

@available(iOS 18.0, *)
#Preview("Tab Bar - Dark", traits: .sizeThatFitsLayout) {
    TabBarView(selection: .constant(.home))
        .preferredColorScheme(.dark)
}

