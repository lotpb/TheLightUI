//
//  LandMarkCategoryView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI

struct LandMarkCategoryView: View {
    
    private static let categories = [
        "Groceries",
        "Restaurants",
        "Hotels",
        "Coffee",
        "Gas",
        "Takeout",
        "Pharmacies",
        "Burger",
        "ATM",
        "Auto Repair",
        "EV Charging",
        "Hardware",
        "Parks"
    ]
    
    let onSelectedCategory: (String) -> Void
    @State private var selectedCategory = ""
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Self.categories, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            selectedCategory = category
                        }
                        onSelectedCategory(category)
                    } label: {
                        CategoryChip(title: category, isSelected: selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color(.separator).opacity(isSelected ? 0 : 0.12), lineWidth: 1)
            }
    }
}

#Preview("Landmark Categories") {
    LandMarkCategoryView(onSelectedCategory: { _ in })
        .padding()
}
