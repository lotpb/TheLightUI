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
        let clamped = clampedRating
        let stars = StarsRow(max: maxRating, size: starSize) { index in
            withAnimation(.easeOut) { rating = index }
        }

        stars
            .foregroundStyle(.secondary)
            .overlay { Color.yellow.mask(stars).frame(maxWidth: .infinity, alignment: .leading) }
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Color.clear
                        .frame(width: width(for: clamped, total: proxy.size.width))
                }
                .allowsHitTesting(false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rating")
            .accessibilityValue("\(clamped) out of \(maxRating)")
    }

    private var clampedRating: Int { min(max(rating, 0), maxRating) }

    private func width(for rating: Int, total: CGFloat) -> CGFloat {
        guard maxRating > 0 else { return 0 }
        return CGFloat(rating) / CGFloat(maxRating) * total
    }
}

private struct StarsRow: View {
    let max: Int
    let size: Font
    let onTap: (Int) -> Void

    var body: some View {
        HStack {
            ForEach(1...max, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(size)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(index) }
            }
        }
    }
}

#Preview("Star Rating") {
    StarRating(rating: .constant(3))
        .preferredColorScheme(.dark)
}
