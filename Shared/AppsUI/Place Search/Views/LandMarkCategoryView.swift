//
//  LandMarkCategoryView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI

struct Constants {
    static let categories = [
        "Groceries",
        "Restaurants",
        "Hotels",
        "Coffee",
        "Gas",
        "Takeout",
        "Pharmacies",
        "Burger",
        "Auto Repair",
        "Plumbers"
    ]
}


struct LandMarkCategoryView: View {
    
    let onSelectedCategory: (String) -> Void
    @State private var selectedCategory = ""
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        onSelectedCategory(category)
                    }, label: {
                        Text(category)
                            .padding(.vertical, 1)
                            .padding(.horizontal)
                    })
                        .foregroundColor(selectedCategory == category ? Color.primary : Color.secondary)
                        .background(selectedCategory == category ? Color.secondary : Color.white.opacity(0))
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct LandMarkCategoryVie_Previews: PreviewProvider {
  static var previews: some View {
    LandMarkCategoryView(onSelectedCategory: { _ in })
      .previewLayout(.sizeThatFits)
  }
}
