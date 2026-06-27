//
//  InstagramHome.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

@available(iOS 16.0, *)
struct InstagramHome: View {
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
            .background(currentTab.backgroundColor.ignoresSafeArea())
            .navigationTitle(currentTab.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close Instagram home")
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
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

private struct InstagramFeedView: View {
    let stories: [IGStory]
    let posts: [IGFeedPost]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                StoryCarousel(stories: stories)

                ForEach(posts) { post in
                    FeedPostCard(post: post)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

private struct StoryCarousel: View {
    let stories: [IGStory]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(stories) { story in
                    StoryButton(story: story)
                }
            }
            .padding(.horizontal)
        }
        .accessibilityLabel("Stories")
    }
}

private struct StoryButton: View {
    let story: IGStory

    var body: some View {
        Button { } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(story.isLive ? Color.red : Color.pink, lineWidth: 3)
                        .frame(width: 70, height: 70)

                    Image(story.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 62, height: 62)
                        .clipShape(Circle())
                        .background(Circle().fill(Color(.secondarySystemBackground)))

                    if story.isLive {
                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                            .offset(y: 35)
                            .accessibilityHidden(true)
                    }
                }

                Text(story.handle)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 74)
            }
        }
        .accessibilityLabel(story.accessibilityLabel)
    }
}

private struct FeedPostCard: View {
    let post: IGFeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FeedPostHeader(post: post)

            Image(post.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .background(Color(.secondarySystemBackground))
                .accessibilityLabel(post.imageAccessibilityLabel)

            FeedPostActions(post: post)

            VStack(alignment: .leading, spacing: 5) {
                Text(post.likesText)
                    .font(.subheadline.weight(.semibold))

                Text(post.caption)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
    }
}

private struct FeedPostHeader: View {
    let post: IGFeedPost

    var body: some View {
        HStack(spacing: 10) {
            Image(post.avatarImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .background(Circle().fill(Color(.secondarySystemBackground)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.author)
                    .font(.subheadline.weight(.semibold))

                Text(post.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("More options for \(post.author)'s post")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct FeedPostActions: View {
    let post: IGFeedPost

    var body: some View {
        HStack(spacing: 18) {
            ActionIconButton(systemImage: "heart", label: "Like post by \(post.author)")
            ActionIconButton(systemImage: "bubble.right", label: "Comment on post by \(post.author)")
            ActionIconButton(systemImage: "paperplane", label: "Share post by \(post.author)")

            Spacer()

            ActionIconButton(systemImage: "bookmark", label: "Save post by \(post.author)")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct ActionIconButton: View {
    let systemImage: String
    let label: String

    var body: some View {
        Button { } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(label)
    }
}

private struct InstagramSearchView: View {
    let suggestions: [IGSuggestion]
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 2)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Search", systemImage: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(suggestions) { suggestion in
                        SuggestionTile(suggestion: suggestion)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

private struct SuggestionTile: View {
    let suggestion: IGSuggestion

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(suggestion.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .background(Color(.secondarySystemBackground))

            Text(suggestion.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(6)
                .shadow(radius: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Explore \(suggestion.title)")
    }
}

private struct InstagramActivityView: View {
    private let activities = IGActivity.sampleActivities

    var body: some View {
        List(activities) { activity in
            HStack(spacing: 12) {
                Image(activity.systemImage)
                    .font(.headline)
                    .foregroundStyle(activity.color)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(activity.color.opacity(0.12)))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))

                    Text(activity.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .listStyle(.plain)
        .background(Color(.systemBackground))
    }
}

private struct InstagramProfileSummaryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image("taylor_swift_profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 104, height: 104)
                    .clipShape(Circle())
                    .background(Circle().fill(Color(.secondarySystemBackground)))
                    .accessibilityLabel("Profile photo")

                VStack(spacing: 6) {
                    Text("TheLight Studio")
                        .font(.title2.weight(.bold))

                    Text("Building SwiftUI interface studies and practical Apple platform patterns.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    ProfileMetric(value: "199", title: "Posts")
                    ProfileMetric(value: "1.1K", title: "Followers")
                    ProfileMetric(value: "13", title: "Following")
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

private struct ProfileMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(title)")
    }
}

private struct InstagramHomeTabBar: View {
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

private struct InstagramHomeTabButton: View {
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

private enum InstagramHomeTab: String, CaseIterable, Identifiable {
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

private struct IGStory: Identifiable {
    let id = UUID()
    let handle: String
    let imageName: String
    let isLive: Bool

    var accessibilityLabel: String {
        isLive ? "\(handle) live story" : "\(handle) story"
    }

    static let sampleStories = [
        IGStory(handle: "Your story", imageName: "taylor_swift_profile", isLive: true),
        IGStory(handle: "design", imageName: "profile-rabbit-toy", isLive: true),
        IGStory(handle: "swiftui", imageName: "taylor_swift_profile", isLive: false),
        IGStory(handle: "travel", imageName: "profile-rabbit-toy", isLive: false),
        IGStory(handle: "coffee", imageName: "taylor_swift_profile", isLive: false),
        IGStory(handle: "launch", imageName: "profile-rabbit-toy", isLive: true)
    ]
}

private struct IGFeedPost: Identifiable {
    let id = UUID()
    let author: String
    let location: String
    let avatarImageName: String
    let imageName: String
    let likesText: String
    let caption: String
    let timeAgo: String

    var imageAccessibilityLabel: String {
        "Photo posted by \(author) from \(location)"
    }

    static let samplePosts = [
        IGFeedPost(
            author: "TheLight Studio",
            location: "Cupertino, California",
            avatarImageName: "taylor_swift_profile",
            imageName: "ZuckBuddist",
            likesText: "1,248 likes",
            caption: "TheLight Studio New SwiftUI interaction study with cleaner motion and a tighter content layout.",
            timeAgo: "12 minutes ago"
        ),
        IGFeedPost(
            author: "Swift Daily",
            location: "San Francisco, California",
            avatarImageName: "profile-rabbit-toy",
            imageName: "ZuckBuddist",
            likesText: "842 likes",
            caption: "Swift Daily A compact feed card that scales cleanly across content sizes.",
            timeAgo: "1 hour ago"
        ),
        IGFeedPost(
            author: "Design Notes",
            location: "New York, New York",
            avatarImageName: "profile-rabbit-toy",
            imageName: "ZuckBuddist",
            likesText: "2,419 likes",
            caption: "Design Notes Balancing dense controls with generous reading space for everyday app surfaces.",
            timeAgo: "3 hours ago"
        )
    ]
}

private struct IGSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String

    static let sampleSuggestions = [
        IGSuggestion(title: "SwiftUI", imageName: "taylor_swift_profile"),
        IGSuggestion(title: "Design", imageName: "taylor_swift_profile"),
        IGSuggestion(title: "Travel", imageName: "post3"),
        IGSuggestion(title: "Coffee", imageName: "post4"),
        IGSuggestion(title: "Apps", imageName: "post5"),
        IGSuggestion(title: "Motion", imageName: "post6"),
        IGSuggestion(title: "Studio", imageName: "post7"),
        IGSuggestion(title: "Tools", imageName: "post8"),
        IGSuggestion(title: "Launch", imageName: "post9")
    ]
}

private struct IGActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    static let sampleActivities = [
        IGActivity(title: "New follower", subtitle: "Design Notes started following you.", systemImage: "person.badge.plus", color: .blue),
        IGActivity(title: "Post liked", subtitle: "Swift Daily liked your latest post.", systemImage: "heart.fill", color: .pink),
        IGActivity(title: "Comment", subtitle: "TheLight Studio commented on your reel.", systemImage: "bubble.right.fill", color: .green),
        IGActivity(title: "Mention", subtitle: "You were mentioned in a story.", systemImage: "at", color: .orange)
    ]
}

@available(iOS 17.0, *)
#Preview("Instagram Home - Light") {
    InstagramHome()
}

@available(iOS 17.0, *)
#Preview("Instagram Home - Dark") {
    InstagramHome()
        .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Instagram Home - Dynamic Type") {
    InstagramHome()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
