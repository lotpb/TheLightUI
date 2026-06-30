//
//  InstagramModels.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

struct IGStory: Identifiable {
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

struct IGFeedPost: Identifiable {
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

struct IGSuggestion: Identifiable {
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

struct IGActivity: Identifiable {
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
