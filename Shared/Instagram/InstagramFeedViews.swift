//
//  InstagramFeedViews.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

struct InstagramFeedView: View {
    let stories: [IGStory]
    let posts: [IGFeedPost]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                IGStoryCarousel(stories: stories)

                ForEach(posts) { post in
                    IGFeedPostCard(post: post)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

struct IGStoryCarousel: View {
    let stories: [IGStory]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(stories) { story in
                    IGStoryButton(story: story)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel("Stories")
    }
}

struct IGStoryButton: View {
    let story: IGStory

    var body: some View {
        Button { } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(story.isLive ? Color.red : Color.pink, lineWidth: 3)
                        .frame(width: 70, height: 70)

                    ProfileAvatarImage(urlString: story.profileImageUrl, fallbackImageName: story.imageName)
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
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 74)
            }
        }
        .accessibilityLabel(story.accessibilityLabel)
    }
}

struct IGFeedPostCard: View {
    let post: IGFeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IGFeedPostHeader(post: post)

            Image(post.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .background(Color(.secondarySystemBackground))
                .accessibilityLabel(post.imageAccessibilityLabel)

            IGFeedPostActions(post: post)

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

struct IGFeedPostHeader: View {
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

struct IGFeedPostActions: View {
    let post: IGFeedPost

    var body: some View {
        HStack(spacing: 18) {
            IGActionIconButton(systemImage: "heart", label: "Like post by \(post.author)")
            IGActionIconButton(systemImage: "bubble.right", label: "Comment on post by \(post.author)")
            IGActionIconButton(systemImage: "paperplane", label: "Share post by \(post.author)")

            Spacer()

            IGActionIconButton(systemImage: "bookmark", label: "Save post by \(post.author)")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

struct IGActionIconButton: View {
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
