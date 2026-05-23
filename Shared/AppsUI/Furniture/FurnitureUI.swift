//
//  FurnitureUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/28/21.
//

import SwiftUI

struct FurnitureUI: View {
    @State private var search = ""
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Chair", "Sofa", "Lamp", "Kitchen", "Table"]
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
                CustomColor.linenColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        AppBarView()
                        TagLineView()
                            .padding()
                        SearchAndScanView(search: $search)
                        categoriesView
                        ProductSection(title: "Popular", products: filteredPopularProducts, cardSize: 210, showsDetailLinks: true)
                        ProductSection(title: "Best", products: filteredBestProducts, cardSize: 180, showsDetailLinks: false)
                    }
                    .padding(.bottom, 90)
                }
                
                BottomNavBarView()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var categoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CategoryView(isActive: selectedCategory == category, text: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private func filteredProducts(from products: [FurnitureProduct]) -> [FurnitureProduct] {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return products.filter { product in
            let matchesCategory = selectedCategory == "All" || product.category == selectedCategory
            let matchesSearch = trimmedSearch.isEmpty || product.name.localizedCaseInsensitiveContains(trimmedSearch)
            return matchesCategory && matchesSearch
        }
    }
}

#Preview("Furniture - Dark") {
    FurnitureUI()
        .preferredColorScheme(.dark)
}

#Preview("Furniture - Light") {
    FurnitureUI()
}

private struct FurnitureProduct: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let category: String
    let price: String
    let rating: Int
    let description: String
    
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
    
    static let popular = [
        FurnitureProduct(
            name: "Luxury Swedish Chair",
            imageName: "chair_1",
            category: "Chair",
            price: "$1299",
            rating: 5,
            description: "A contemporary chair based on modern craft, with a simple frame and polished lounge proportions."
        ),
        FurnitureProduct(
            name: "Linen Lounge Chair",
            imageName: "chair_2",
            category: "Chair",
            price: "$899",
            rating: 4,
            description: "A soft linen lounge chair designed for calm reading corners and relaxed living rooms."
        ),
        FurnitureProduct(
            name: "Modern Reading Chair",
            imageName: "chair_3",
            category: "Chair",
            price: "$1049",
            rating: 5,
            description: "A structured reading chair with generous support and a refined modern profile."
        ),
        FurnitureProduct(
            name: "Soft Accent Chair",
            imageName: "chair_4",
            category: "Chair",
            price: "$749",
            rating: 4,
            description: "A compact accent chair with soft edges for bedrooms, offices, and small sitting areas."
        )
    ]
    
    static var best: [FurnitureProduct] {
        popular.reversed()
    }
}

private struct ProductSection: View {
    let title: String
    let products: [FurnitureProduct]
    let cardSize: CGFloat
    let showsDetailLinks: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("PlayfairDisplay-Bold", size: 24))
                .padding(.horizontal)
                .foregroundColor(.black)
            
            if products.isEmpty {
                Text("No furniture found")
                    .foregroundColor(.black.opacity(0.5))
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(products) { product in
                            if showsDetailLinks {
                                NavigationLink {
                                    FurnitureDetail(product: product.detailProduct)
                                } label: {
                                    ProductCardView(product: product, size: cardSize)
                                }
                                .foregroundColor(.black)
                            } else {
                                ProductCardView(product: product, size: cardSize)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.leading)
                    }
                }
            }
        }
        .padding(.bottom)
    }
}

private struct AppBarView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "person")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image("taylor_swift_profile")
                    .resizable()
                    .frame(width: 42, height: 42)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

private struct TagLineView: View {
    var body: some View {
        Text("Find the \nBest ")
            .font(.custom("PlayfairDisplay-Regular", size: 28))
            .foregroundColor(.black)
        + Text("Furniture!")
            .font(.custom("PlayfairDisplay-Bold", size: 28))
            .fontWeight(.bold)
            .foregroundColor(.black)
    }
}

private struct SearchAndScanView: View {
    @Binding var search: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.trailing, 8)
                TextField("Search Furniture", text: $search)
                    .textInputAutocapitalization(.words)
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.trailing, 8)
            
            Button(action: {}) {
                Image(systemName: "qrcode.viewfinder")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .foregroundColor(.black)
        .padding(.horizontal)
    }
}

private struct CategoryView: View {
    let isActive: Bool
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(isActive ? .black : .black.opacity(0.5))
            
            if isActive {
                Color.white
                    .frame(width: 15, height: 2)
                    .clipShape(Capsule())
            }
        }
        .padding(.trailing)
    }
}

private struct ProductCardView: View {
    let product: FurnitureProduct
    let size: CGFloat
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(product.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: 200 * (size / 210))
                .clipped()
                .cornerRadius(20)
            
            Text(product.name)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(2)
            
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < product.rating ? "star.fill" : "star")
                        .font(.caption2)
                }
                Spacer()
                Text(product.price)
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .frame(width: size)
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

private struct BottomNavBarView: View {
    var body: some View {
        HStack {
            BottomNavBarItem(systemImage: "star", action: {})
            BottomNavBarItem(systemImage: "bell", action: {})
            BottomNavBarItem(systemImage: "cart", action: {})
            BottomNavBarItem(systemImage: "person", action: {})
        }
        .padding()
        .background(Color.white)
        .foregroundColor(.black)
        .clipShape(Capsule())
        .padding(.horizontal)
        .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 2, y: 6)
    }
}

private struct BottomNavBarItem: View {
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(maxWidth: .infinity)
        }
    }
}
