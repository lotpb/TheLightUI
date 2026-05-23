//
//  StarRating.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/23/21.
//

import SwiftUI

struct StarRating: View {
    @Binding private var rating: Int
    
    private let maxRating: Int
    private let starSize: Font
    
    init(
        rating: Binding<Int> = .constant(0),
        maxRating: Int = 5,
        starSize: Font = .largeTitle
    ) {
        _rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
    }
    
    var body: some View {
        starsView
            .overlay(overlayView.mask(starsView))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rating")
            .accessibilityValue("\(clampedRating) out of \(maxRating)")
    }
    
    private var overlayView: some View {
        GeometryReader { geometry in
            Rectangle()
                .foregroundColor(.yellow)
                .frame(width: ratingWidth(in: geometry.size.width), alignment: .leading)
        }
        .allowsHitTesting(false)
    }
    
    private var starsView: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(starSize)
                    .foregroundColor(.secondary)
                    .onTapGesture {
                        withAnimation(.easeOut) {
                            rating = index
                        }
                    }
            }
        }
    }
    
    private var clampedRating: Int {
        min(max(rating, 0), maxRating)
    }
    
    private func ratingWidth(in totalWidth: CGFloat) -> CGFloat {
        guard maxRating > 0 else { return 0 }
        return CGFloat(clampedRating) / CGFloat(maxRating) * totalWidth
    }
}

#Preview("Star Rating") {
    StarRating(rating: .constant(3))
        .preferredColorScheme(.dark)
}
