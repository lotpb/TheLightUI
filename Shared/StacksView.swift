//
//  Stacks.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/18/22.
//

import SwiftUI

// MARK: - Stacks
struct StacksView: View {
    private enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let gridSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 28
        static let verticalPadding: CGFloat = 24
    }

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: Layout.gridSpacing),
        GridItem(.flexible(), spacing: Layout.gridSpacing)
    ]

    private var sections: [StackSection] {
        let allSections = StackSection.sampleSections
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allSections }

        return allSections.compactMap { section in
            let cards = section.cards.filter { card in
                card.title.localizedCaseInsensitiveContains(query) ||
                section.title.localizedCaseInsensitiveContains(query)
            }
            return cards.isEmpty ? nil : StackSection(title: section.title, cards: cards)
        }
    }

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("Stacks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .frame(maxWidth: Layout.maxContentWidth)
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                if sections.isEmpty {
                    emptyState
                } else {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
            }
            .padding(.vertical, Layout.verticalPadding)
        }
    }

    private func sectionView(_ section: StackSection) -> some View {
        VStack(alignment: .leading, spacing: Layout.gridSpacing) {
            Text(section.title)
                .font(.headline.bold())
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                ForEach(section.cards) { card in
                    StackCategoryCard(card: card)
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
            Text("No Results")
                .font(.headline)
            Text("Try another search.")
                .font(.subheadline)
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle.fill")
            }
        }
    }
}

// MARK: - Models
private struct StackSection: Identifiable {
    let id = UUID()
    let title: String
    let cards: [StackCard]

    static let sampleSections = [
        StackSection(title: "Your top genres", cards: [
            StackCard(title: "Furniture", imageName: "chair_1", color: .brown),
            StackCard(title: "Freaks", imageName: "ZuckBuddist", color: .purple)
        ]),
        StackSection(title: "Featured podcast categories", cards: [
            StackCard(title: "Podcast New\nReleases", imageName: "taylor_swift_profile", color: .pink),
            StackCard(title: "True Crime\nScene", imageName: "chair_2", color: .blue)
        ]),
        StackSection(title: "Browse all", cards: [
            StackCard(title: "Products", imageName: "profile-rabbit-toy", color: .red),
            StackCard(title: "Made for\nyou", imageName: "IMG_3408", color: .indigo)
        ])
    ]
}

private struct StackCard: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

// MARK: - Card
private struct StackCategoryCard: View {
    private enum Layout {
        static let cornerRadius: CGFloat = 7
        static let imageCornerRadius: CGFloat = 5
        static let imageSize: CGFloat = 75
        static let cardHeight: CGFloat = 100
        static let imageXOffset: CGFloat = 18
        static let imageRotation: Double = 25
    }

    let card: StackCard

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(card.color)

            title
            artwork
        }
        .frame(height: Layout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
    }

    private var title: some View {
        Text(card.title)
            .font(.headline.bold())
            .foregroundColor(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
    }

    private var artwork: some View {
        Image(card.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: Layout.imageSize, height: Layout.imageSize)
            .clipShape(RoundedRectangle(cornerRadius: Layout.imageCornerRadius, style: .continuous))
            .rotationEffect(.degrees(Layout.imageRotation))
            .offset(x: Layout.imageXOffset)
    }
}

// MARK: - Preview
#Preview("Stacks - Dark") {
    StacksView()
        .preferredColorScheme(.dark)
}
