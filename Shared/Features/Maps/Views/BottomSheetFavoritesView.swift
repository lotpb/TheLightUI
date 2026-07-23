//
//  BottomSheetFavoritesView.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetFavoritesView: View {
    let favorites: [BottomSheetFavorite]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Favorites")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(favorites) { favorite in
                        favoriteButton(favorite)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func favoriteButton(_ favorite: BottomSheetFavorite) -> some View {
        VStack(spacing: 8) {
            Button { } label: {
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                    Image(systemName: favorite.systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(favorite.color)
                }
                .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)

            Text(favorite.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
