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
    @Environment(\.dismiss) private var dismiss

    private let product: FurnitureDetailProduct
    private let maxWidthForIpad: CGFloat = 700

    init(product: FurnitureDetailProduct = .defaultProduct) {
        self.product = product
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CustomColor.linenColor
                .ignoresSafeArea()

            content
            bottomBar
        }
        .frame(maxWidth: maxWidthForIpad)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            leadingToolbarItem
            trailingToolbarItem
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: true) {
            productImage
            DescriptionView(product: product)
        }
        .foregroundColor(.black)
        .ignoresSafeArea(edges: .top)
    }

    private var productImage: some View {
        Image(product.imageName)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .ignoresSafeArea(edges: .top)
    }

    private var bottomBar: some View {
        BottomBar(product: product)
    }

    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            BackButton {
                dismiss()
            }
        }
    }

    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {}) {
                Image(systemName: "star")
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - Description View

private struct DescriptionView: View {
    let product: FurnitureDetailProduct

    @State private var quantity = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.title)
                .font(.title)
                .fontWeight(.bold)

            ratingView
            descriptionSection
            infoSection
            colorsAndQuantitySection
        }
        .padding()
        .padding(.top)
        .background(CustomColor.linenColor)
        .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30))
        .offset(y: -30)
    }

    private var ratingView: some View {
        RatingView(rating: product.rating)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .fontWeight(.medium)

            Text(product.description)
                .lineSpacing(8)
                .opacity(0.6)
        }
        .padding(.vertical, 8)
    }

    private var infoSection: some View {
        HStack(alignment: .top) {
            sizeSection

            Spacer()

            treatmentSection
        }
        .padding(.vertical)
    }

    private var sizeSection: some View {
        ProductInfoColumn(title: "Size", values: product.sizes)
    }

    private var treatmentSection: some View {
        ProductInfoColumn(title: "Treatment", values: [product.treatment])
    }

    private var colorsAndQuantitySection: some View {
        HStack {
            colorsSection
            quantityStepper
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading) {
            Text("Colors")
                .fontWeight(.semibold)

            HStack {
                ForEach(Array(product.colors.enumerated()), id: \.offset) { _, color in
                    ColorDotView(color: color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quantityStepper: some View {
        QuantityStepper(quantity: $quantity)
    }
}

// MARK: - Supporting Views

private struct BottomBar: View {
    let product: FurnitureDetailProduct

    var body: some View {
        HStack {
            Text(product.price)
                .font(.title)
                .foregroundColor(.black)

            Spacer()

            Button(action: {}) {
                Text("Add to Cart")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding()
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .padding(.horizontal)
        .background(Color.white)
        .clipShape(CustomCorners(corners: .topLeft, radius: 60))
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: Double(index) < rating.rounded(.down) ? "star.fill" : "star")
            }

            Text("(\(rating, specifier: "%.1f"))")
                .opacity(0.5)
                .padding(.leading, 8)

            Spacer()
        }
    }
}

private struct ProductInfoColumn: View {
    let title: String
    let values: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16))
                .fontWeight(.semibold)

            ForEach(values, id: \.self) { value in
                Text(value)
                    .opacity(0.6)
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
                quantity = max(1, quantity - 1)
            } label: {
                Image(systemName: "minus")
                    .padding(8)
            }
            .frame(width: 30, height: 30)
            .overlay(Circle().stroke())
            .foregroundColor(.black)

            Text("\(quantity)")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)

            Button {
                quantity += 1
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
    }
}

private struct ColorDotView: View {
    let color: Color

    var body: some View {
        color
            .frame(width: 24, height: 24)
            .clipShape(Circle())
    }
}

private struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .foregroundColor(.black)
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview("Furniture Detail") {
    NavigationStack {
        FurnitureDetail()
    }
}
