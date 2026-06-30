//
//  FurnitureDetail.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/28/21.
//

import SwiftUI

// MARK: - Model

struct FurnitureDetailProduct {
    let title: String
    let imageName: String
    let price: String
    let rating: Double
    let description: String
    let sizes: [String]
    let treatment: String
    let colors: [Color]
}

extension FurnitureDetailProduct {
    static let defaultProduct = FurnitureDetailProduct(
        title: "Luxury Swedish Chair",
        imageName: "chair_1",
        price: "$1299",
        rating: 4.9,
        description: "Luxury Swedish Chair is a contemporary chair based on the virtues of modern craft. It carries on the simplicity and honesty of the archetypal chair.",
        sizes: ["Height: 120 cm", "Wide: 80 cm", "Diameter: 72 cm"],
        treatment: "Jati Wood, Canvas,\nAmazing Love",
        colors: [.white, .black, Color(red: 0.18, green: 0.64, blue: 0.67)]
    )
}

// MARK: - Detail View

struct FurnitureDetail: View {
    fileprivate enum Layout {
        static let maxContentWidth: CGFloat = 700
        static let detailCornerRadius: CGFloat = 30
        static let bottomBarCornerRadius: CGFloat = 60
        static let buttonCornerRadius: CGFloat = 10
        static let toolbarButtonCornerRadius: CGFloat = 8
        static let colorDotSize: CGFloat = 24
        static let quantityButtonSize: CGFloat = 30
    }

    @Environment(\.dismiss) private var dismiss

    private let product: FurnitureDetailProduct

    init(product: FurnitureDetailProduct = .defaultProduct) {
        self.product = product
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            FurnitureDetailStyle.background
                .ignoresSafeArea()

            content
            BottomBar(product: product)
        }
        .frame(maxWidth: Layout.maxContentWidth)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton()
            }
        }
    }

    private var content: some View {
        ScrollView {
            productImage
            DescriptionView(product: product)
        }
        .foregroundStyle(FurnitureDetailStyle.primaryText)
        .ignoresSafeArea(edges: .top)
    }

    private var productImage: some View {
        Image(product.imageName)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .ignoresSafeArea(edges: .top)
            .accessibilityLabel(product.title)
    }
}

private enum FurnitureDetailStyle {
    static let background = CustomColor.linenColor
    static let primaryText = Color.black
    static let secondaryText = Color.black.opacity(0.6)
    static let controlBackground = Color.white
}

// MARK: - Description View

private struct DescriptionView: View {
    let product: FurnitureDetailProduct

    @State private var quantity = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.title)
                .font(.title.weight(.bold))

            RatingView(rating: product.rating)
            descriptionSection
            infoSection
            colorsAndQuantitySection
        }
        .padding()
        .padding(.top)
        .background(FurnitureDetailStyle.background)
        .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: FurnitureDetail.Layout.detailCornerRadius))
        .offset(y: -30)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .fontWeight(.medium)

            Text(product.description)
                .lineSpacing(8)
                .foregroundStyle(FurnitureDetailStyle.secondaryText)
        }
        .padding(.vertical, 8)
    }

    private var infoSection: some View {
        HStack(alignment: .top) {
            ProductInfoColumn(title: "Size", values: product.sizes)

            Spacer()

            ProductInfoColumn(title: "Treatment", values: [product.treatment])
        }
        .padding(.vertical)
    }

    private var colorsAndQuantitySection: some View {
        HStack {
            colorsSection
            QuantityStepper(quantity: $quantity)
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading) {
            Text("Colors")
                .fontWeight(.semibold)

            HStack {
                ForEach(Array(product.colors.enumerated()), id: \.offset) { index, color in
                    ColorDotView(color: color)
                        .accessibilityLabel("Color option \(index + 1)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Supporting Views

private struct BottomBar: View {
    let product: FurnitureDetailProduct

    var body: some View {
        HStack {
            Text(product.price)
                .font(.title)
                .foregroundStyle(FurnitureDetailStyle.primaryText)

            Spacer()

            Button(action: {}) {
                Text("Add to Cart")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(FurnitureDetailStyle.primaryText)
                    .padding()
                    .padding(.horizontal, 8)
                    .background(
                        FurnitureDetailStyle.controlBackground,
                        in: RoundedRectangle(cornerRadius: FurnitureDetail.Layout.buttonCornerRadius, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(product.title) to cart")
        }
        .padding()
        .padding(.horizontal)
        .background(FurnitureDetailStyle.controlBackground)
        .clipShape(CustomCorners(corners: .topLeft, radius: FurnitureDetail.Layout.bottomBarCornerRadius))
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct RatingView: View {
    let rating: Double

    private var filledStarCount: Int {
        Int(rating.rounded(.down))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < filledStarCount ? "star.fill" : "star")
            }

            Text("(\(rating, specifier: "%.1f"))")
                .foregroundStyle(FurnitureDetailStyle.secondaryText)
                .padding(.leading, 8)

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(rating, specifier: "%.1f") out of 5")
    }
}

private struct ProductInfoColumn: View {
    let title: String
    let values: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))

            ForEach(values, id: \.self) { value in
                Text(value)
                    .foregroundStyle(FurnitureDetailStyle.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct QuantityStepper: View {
    @Binding var quantity: Int

    var body: some View {
        HStack {
            Button {
                decrement()
            } label: {
                Image(systemName: "minus")
                    .frame(width: FurnitureDetail.Layout.quantityButtonSize, height: FurnitureDetail.Layout.quantityButtonSize)
                    .overlay(Circle().stroke(FurnitureDetailStyle.primaryText))
            }
            .disabled(quantity == 1)
            .foregroundStyle(FurnitureDetailStyle.primaryText)
            .accessibilityLabel("Decrease quantity")

            Text("\(quantity)")
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 8)
                .monospacedDigit()
                .accessibilityLabel("Quantity \(quantity)")

            Button {
                increment()
            } label: {
                Image(systemName: "plus")
                    .frame(width: FurnitureDetail.Layout.quantityButtonSize, height: FurnitureDetail.Layout.quantityButtonSize)
                    .foregroundStyle(FurnitureDetailStyle.primaryText)
                    .background(FurnitureDetailStyle.controlBackground, in: Circle())
            }
            .accessibilityLabel("Increase quantity")
        }
    }

    private func decrement() {
        quantity = max(1, quantity - 1)
    }

    private func increment() {
        quantity += 1
    }
}

private struct ColorDotView: View {
    let color: Color

    var body: some View {
        color
            .frame(width: FurnitureDetail.Layout.colorDotSize, height: FurnitureDetail.Layout.colorDotSize)
            .clipShape(Circle())
    }
}

private struct FavoriteButton: View {
    @State private var isFavorite = false

    var body: some View {
        Button {
            isFavorite.toggle()
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(FurnitureDetailStyle.primaryText)
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

private struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .foregroundStyle(FurnitureDetailStyle.primaryText)
                .padding(12)
                .background(
                    FurnitureDetailStyle.controlBackground,
                    in: RoundedRectangle(cornerRadius: FurnitureDetail.Layout.toolbarButtonCornerRadius, style: .continuous)
                )
        }
        .accessibilityLabel("Back")
    }
}

// MARK: - Preview

#Preview("Furniture Detail") {
    NavigationStack {
        FurnitureDetail()
    }
}
