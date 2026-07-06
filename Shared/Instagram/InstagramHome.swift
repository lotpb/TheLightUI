//
//  InstagramHome.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

struct InstagramHome: View {
    private enum Layout {
        // Matches TwitterUI.Layout.maxContentWidth so both read the same on iPad.
        static let maxContentWidth: CGFloat = 700
    }

    @State private var currentTab = InstagramHomeTab.home
    @Environment(\.dismiss) private var dismiss

    private let stories = IGStory.sampleStories
    private let posts = IGFeedPost.samplePosts
    private let suggestions = IGSuggestion.sampleSuggestions

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentTab) {
                    InstagramFeedView(stories: stories, posts: posts)
                        .tag(InstagramHomeTab.home)

                    InstagramSearchView(suggestions: suggestions)
                        .tag(InstagramHomeTab.search)

                    ReelsView()
                        .tag(InstagramHomeTab.reels)

                    InstagramActivityView()
                        .tag(InstagramHomeTab.activity)

                    InstagramProfileSummaryView()
                        .tag(InstagramHomeTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                InstagramHomeTabBar(currentTab: $currentTab)
            }
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
            .background(currentTab.backgroundColor.ignoresSafeArea())
            .navigationTitle(currentTab.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close Instagram home")
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Create new post")

            Button { } label: {
                Image(systemName: "paperplane")
            }
            .accessibilityLabel("Open direct messages")
        }
    }
}

// MARK: - Tab Bar

struct InstagramHomeTabBar: View {
    @Binding var currentTab: InstagramHomeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InstagramHomeTab.allCases) { tab in
                InstagramHomeTabButton(
                    tab: tab,
                    isSelected: currentTab == tab,
                    select: { select(tab) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(currentTab.tabBarBackground)
        .overlay(Divider(), alignment: .top)
    }

    private func select(_ tab: InstagramHomeTab) {
        withAnimation(.snappy) {
            currentTab = tab
        }
    }
}

struct InstagramHomeTabButton: View {
    let tab: InstagramHomeTab
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Image(systemName: isSelected ? tab.selectedSystemImage : tab.systemImage)
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(isSelected ? tab.selectedColor : .secondary)
        }
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tab

enum InstagramHomeTab: String, CaseIterable, Identifiable {
    case home
    case search
    case reels
    case activity
    case profile

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .home: return "Instagram"
        case .search: return "Explore"
        case .reels: return "Reels"
        case .activity: return "Activity"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .reels: return "film"
        case .activity: return "heart"
        case .profile: return "person.circle"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .reels: return "film.fill"
        case .activity: return "heart.fill"
        case .profile: return "person.circle.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .home: return "Home tab"
        case .search: return "Search tab"
        case .reels: return "Reels tab"
        case .activity: return "Activity tab"
        case .profile: return "Profile tab"
        }
    }

    var selectedColor: Color {
        isImmersive ? .white : .primary
    }

    var backgroundColor: Color {
        surfaceColor
    }

    var tabBarBackground: Color {
        surfaceColor
    }

    private var surfaceColor: Color {
        isImmersive ? .black : Color(.systemBackground)
    }

    private var isImmersive: Bool {
        self == .reels
    }
}

// MARK: - Preview

#Preview("Instagram Home - Light") {
    InstagramHome()
}

#Preview("Instagram Home - Dark") {
    InstagramHome()
        .preferredColorScheme(.dark)
}

#Preview("Instagram Home - Dynamic Type") {
    InstagramHome()
        .environment(\.dynamicTypeSize, .accessibility5)
}
