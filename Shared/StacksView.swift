//
//  Stacks.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/18/22.
//

import SwiftUI

struct StacksView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private let maxWidthForIpad: CGFloat = 700
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var sections: [StackSection] {
        let allSections = StackSection.sampleSections
        guard !searchText.isEmpty else { return allSections }
        
        return allSections.compactMap { section in
            let cards = section.cards.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                section.title.localizedCaseInsensitiveContains(searchText)
            }
            return cards.isEmpty ? nil : StackSection(title: section.title, cards: cards)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.headline.bold())
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(section.cards) { card in
                                    StackCategoryCard(card: card)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if sections.isEmpty {
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
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Stacks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .frame(maxWidth: maxWidthForIpad)
    }
}

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

private struct StackCategoryCard: View {
    let card: StackCard
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(card.color)
            
            Text(card.title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            
            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 75, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .rotationEffect(.degrees(25))
                .offset(x: 18)
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview("Stacks - Dark") {
    StacksView()
        .preferredColorScheme(.dark)
}
