//
//  InstagramDiscoverViews.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

struct InstagramSearchView: View {
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
                        IGSuggestionTile(suggestion: suggestion)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct IGSuggestionTile: View {
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

struct InstagramActivityView: View {
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

struct InstagramProfileSummaryView: View {
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
                    IGProfileMetric(value: "199", title: "Posts")
                    IGProfileMetric(value: "1.1K", title: "Followers")
                    IGProfileMetric(value: "13", title: "Following")
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct IGProfileMetric: View {
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
