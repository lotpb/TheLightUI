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
            HStack(alignment: .firstTextBaseline) {
                Text(section.title)
                    .font(.headline.bold())
                Spacer()
                Text("\(section.cards.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                ForEach(section.cards) { card in
                    if let destination = card.destination {
                        NavigationLink {
                            destinationView(for: destination)
                        } label: {
                            StackCategoryCard(card: card)
                        }
                        .buttonStyle(PressableCardStyle())
                    } else {
                        StackCategoryCard(card: card)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: StackDestination) -> some View {
        switch destination {
        case .furniture:
            FurnitureUI()
        case .chart:
            ChartView()
        case .iMac:
            iMacUI()
        case .spotify:
            SpotifyUI()
        case .wave:
            WaveUI()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView.search(text: searchText)
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
private enum StackDestination {
    case furniture
    case chart
    case iMac
    case spotify
    case wave
}

private struct StackSection: Identifiable {
    let id = UUID()
    let title: String
    let cards: [StackCard]

    static let sampleSections = [
        StackSection(title: "Your top genres", cards: [
            StackCard(title: "Furniture", imageName: "chair_1", color: .brown, destination: .furniture),
            StackCard(title: "iMac", imageName: "ZuckBuddist", color: .purple, destination: .iMac)
        ]),
        StackSection(title: "Featured podcast categories", cards: [
            StackCard(title: "Spotify", imageName: "taylor_swift_profile", color: .pink, destination: .spotify),
            StackCard(title: "Wave", imageName: "chair_2", color: .blue, destination: .wave)
        ]),
        StackSection(title: "Browse all", cards: [
            StackCard(title: "Products", imageName: "profile-rabbit-toy", color: .red, destination: .chart),
            StackCard(title: "Made for\nyou", imageName: "IMG_3408", color: .indigo, destination: .chart)
        ])
    ]
}

private struct StackCard: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
    let destination: StackDestination?

    init(title: String, imageName: String, color: Color, destination: StackDestination? = nil) {
        self.title = title
        self.imageName = imageName
        self.color = color
        self.destination = destination
    }
}

// MARK: - Card
private struct StackCategoryCard: View {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let imageCornerRadius: CGFloat = 6
        static let imageSize: CGFloat = 75
        static let cardHeight: CGFloat = 100
        static let imageXOffset: CGFloat = 18
        static let imageRotation: Double = 25
    }

    let card: StackCard

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [card.color, card.color.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            title
            artwork
        }
        .frame(height: Layout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
        .shadow(color: card.color.opacity(0.35), radius: 6, x: 0, y: 4)
    }

    private var title: some View {
        Text(card.title)
            .font(.headline.bold())
            .foregroundStyle(.white)
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

// MARK: - Button Style

/// Gives navigable cards a subtle tactile press-down response.
private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Stacks - Dark") {
    StacksView()
        .preferredColorScheme(.dark)
}

