//
//  FurnitureModels.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/28/21.
//

import SwiftUI

enum FurnitureCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case chair = "Chair"
    case sofa = "Sofa"
    case lamp = "Lamp"
    case kitchen = "Kitchen"
    case table = "Table"

    var id: String { rawValue }
}

struct FurnitureProduct: Identifiable {
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

extension FurnitureProduct {
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

enum FurnitureNavItem: String, CaseIterable, Identifiable {
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
