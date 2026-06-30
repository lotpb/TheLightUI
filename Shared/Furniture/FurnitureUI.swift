//
//  FurnitureUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/28/21.
//

import SwiftUI

// MARK: - Model

private enum FurnitureCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case chair = "Chair"
    case sofa = "Sofa"
    case lamp = "Lamp"
    case kitchen = "Kitchen"
    case table = "Table"

    var id: String { rawValue }
}

private struct FurnitureProduct: Identifiable {
    let id: String
    let name: String
    let imageName: String
    let category: FurnitureCategory
    let price: String
    let rating: Int
    let description: String

    init(
        id: String = UUID().uuidString,
        name: String,
        imageName: String,
        category: FurnitureCategory,
        price: String,
        rating: Int,
        description: String
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.category = category
        self.price = price
        self.rating = rating
        self.description = description
    }

    var detailProduct: FurnitureDetailProduct {
        FurnitureDetailProduct(
            title: name,
            imageName: imageName,
            price: price,
            rating: Double(rating),
            description: description,
            sizes: ["Height: 120 cm", "Wide: 80 cm", "Diameter: 72 cm"],
            treatment: "Jati Wood, Canvas,\nAmazing Love",
            colors: [.white, .black, Color(red: 0.18, green: 0.64, blue: 0.67)]
        )
    }
}

private extension FurnitureProduct {
    static let popular = [
        FurnitureProduct(
            name: "Luxury Swedish Chair",
            imageName: "chair_1",
            category: .chair,
            price: "$1299",
            rating: 5,
            description: "A contemporary chair based on modern craft, with a simple frame and polished lounge proportions."
        ),
        FurnitureProduct(
            name: "Linen Lounge Chair",
            imageName: "chair_2",
            category: .chair,
            price: "$899",
            rating: 4,
            description: "A soft linen lounge chair designed for calm reading corners and relaxed living rooms."
        ),
        FurnitureProduct(
            name: "Modern Reading Chair",
            imageName: "chair_3",
            category: .chair,
            price: "$1049",
            rating: 5,
            description: "A structured reading chair with generous support and a refined modern profile."
        ),
        FurnitureProduct(
            name: "Soft Accent Chair",
            imageName: "chair_4",
            category: .chair,
            price: "$749",
            rating: 4,
            description: "A compact accent chair with soft edges for bedrooms, offices, and small sitting areas."
        )
    ]

    static var best: [FurnitureProduct] {
        popular.reversed()
    }
}

// MARK: - Furniture View

struct FurnitureUI: View {
    @State private var search = ""
    @State private var selectedCategory = FurnitureCategory.all
    @State private var selectedNavItem = FurnitureNavItem.home

    private let categories = FurnitureCategory.allCases
    private let popularProducts = FurnitureProduct.popular
    private let bestProducts = FurnitureProduct.best

    private var filteredPopularProducts: [FurnitureProduct] {
        filteredProducts(from: popularProducts)
    }

    private var filteredBestProducts: [FurnitureProduct] {
        filteredProducts(from: bestProducts)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                FurnitureBackground()
                content
                BottomNavBarView(selectedItem: $selectedNavItem)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(maxWidth: .infinity)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                AppBarView()
                TagLineView()
                SearchAndScanView(search: $search)
                CategorySelectorView(categories: categories, selectedCategory: $selectedCategory)

                ProductSection(
                    title: "Popular",
                    subtitle: "Curated pieces for calm rooms",
                    products: filteredPopularProducts,
                    cardSize: 150,
                    showsDetailLinks: true
                )

                ProductSection(
                    title: "Best",
                    subtitle: "Designs customers save most",
                    products: filteredBestProducts,
                    cardSize: 150,
                    showsDetailLinks: false
                )
            }
            .padding(.top, 12)
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
    }

    private func filteredProducts(from products: [FurnitureProduct]) -> [FurnitureProduct] {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)

        return products.filter { product in
            let matchesCategory = selectedCategory == .all || product.category == selectedCategory
            let matchesSearch = trimmedSearch.isEmpty || product.name.localizedCaseInsensitiveContains(trimmedSearch)
            return matchesCategory && matchesSearch
        }
    }
}

private enum FurnitureStyle {
    static let ink = CustomColor.furnitureInk
    static let secondaryInk = CustomColor.furnitureSecondaryInk
    static let accent = CustomColor.furnitureAccent
    static let coral = CustomColor.furnitureCoral
    static let control = CustomColor.furnitureControl
}

private struct FurnitureBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 0.96),
                    Color(red: 0.86, green: 0.93, blue: 0.91),
                    Color(red: 0.98, green: 0.88, blue: 0.83)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Color.white.opacity(0.55)
                    .frame(height: 220)
                    .blur(radius: 36)

                Spacer()

                FurnitureStyle.coral.opacity(0.13)
                    .frame(height: 150)
                    .blur(radius: 48)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Product Section

private struct ProductSection: View {
    let title: String
    let subtitle: String
    let products: [FurnitureProduct]
    let cardSize: CGFloat
    let showsDetailLinks: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader

            if products.isEmpty {
                emptyState
            } else {
                productCarousel
            }
        }
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(FurnitureStyle.ink)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(FurnitureStyle.secondaryInk)
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chair.lounge")
                .font(.title2)
                .foregroundStyle(FurnitureStyle.accent)

            Text("No furniture found")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FurnitureStyle.ink)

            Text("Try another search or category.")
                .font(.footnote)
                .foregroundStyle(FurnitureStyle.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(FurnitureStyle.control, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var productCarousel: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(products) { product in
                    productCard(for: product)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func productCard(for product: FurnitureProduct) -> some View {
        if showsDetailLinks {
            NavigationLink {
                FurnitureDetail(product: product.detailProduct)
            } label: {
                ProductCardView(product: product, size: cardSize)
            }
            .buttonStyle(.plain)
        } else {
            ProductCardView(product: product, size: cardSize)
        }
    }
}

private struct ProductCardView: View {
    let product: FurnitureProduct
    let size: CGFloat

    private var imageHeight: CGFloat {
        178 * (size / 214)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            productImage
            productInfo
            ratingAndPrice
        }
        .padding(12)
        .frame(width: size)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.70), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var productImage: some View {
        ZStack(alignment: .topTrailing) {
            Image(product.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size - 24, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Image(systemName: "heart")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FurnitureStyle.ink)
                .padding(8)
                .background(.white.opacity(0.78), in: Circle())
                .padding(8)
        }
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.category.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FurnitureStyle.accent)

            Text(product.name)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(FurnitureStyle.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ratingAndPrice: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)

            Text("\(product.rating).0")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FurnitureStyle.secondaryInk)

            Spacer(minLength: 8)

            Text(product.price)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(FurnitureStyle.ink)
        }
    }
}

// MARK: - Header

private struct AppBarView: View {
    var body: some View {
        HStack {
            IconButton(systemImage: "line.3.horizontal", accessibilityLabel: "Open menu") {}

            Spacer()

            Image("taylor_swift_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 20)
    }
}

private struct TagLineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Furniture Studio")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(FurnitureStyle.accent)

            Text("Find the best furniture for your space")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(FurnitureStyle.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 20)
    }
}

private struct SearchAndScanView: View {
    @Binding var search: String

    var body: some View {
        HStack(spacing: 12) {
            searchField
            IconButton(systemImage: "qrcode.viewfinder", accessibilityLabel: "Scan furniture") {}
        }
        .padding(.horizontal, 20)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FurnitureStyle.secondaryInk)

            TextField("Search furniture", text: $search)
                .textInputAutocapitalization(.words)
                .foregroundStyle(FurnitureStyle.ink)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(FurnitureStyle.control, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
    }
}

private struct IconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(FurnitureStyle.ink)
                .frame(width: 44, height: 44)
                .background(FurnitureStyle.control, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Categories

private struct CategorySelectorView: View {
    let categories: [FurnitureCategory]

    @Binding var selectedCategory: FurnitureCategory

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        select(category)
                    } label: {
                        CategoryView(isActive: selectedCategory == category, text: category.rawValue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func select(_ category: FurnitureCategory) {
        withAnimation(.snappy(duration: 0.25, extraBounce: 0.1)) {
            selectedCategory = category
        }
    }
}

private struct CategoryView: View {
    let isActive: Bool
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isActive ? .white : FurnitureStyle.secondaryInk)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(isActive ? FurnitureStyle.ink : FurnitureStyle.control, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isActive ? .clear : .white.opacity(0.70), lineWidth: 1)
            }
    }
}

// MARK: - Bottom Navigation

private enum FurnitureNavItem: String, CaseIterable, Identifiable {
    case home
    case favorites
    case cart
    case profile

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .favorites: return "heart"
        case .cart: return "cart"
        case .profile: return "person"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .home: return "Home"
        case .favorites: return "Favorites"
        case .cart: return "Cart"
        case .profile: return "Profile"
        }
    }
}

private struct BottomNavBarView: View {
    @Binding var selectedItem: FurnitureNavItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FurnitureNavItem.allCases) { item in
                BottomNavBarItem(
                    systemImage: item.systemImage,
                    isActive: selectedItem == item,
                    accessibilityLabel: item.accessibilityLabel
                ) {
                    selectedItem = item
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 12)
    }
}

private struct BottomNavBarItem: View {
    let systemImage: String
    let isActive: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isActive ? .white : FurnitureStyle.secondaryInk)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? FurnitureStyle.ink : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Furniture - Dark") {
    FurnitureUI()
        .preferredColorScheme(.dark)
}

#Preview("Furniture - Light") {
    FurnitureUI()
}
