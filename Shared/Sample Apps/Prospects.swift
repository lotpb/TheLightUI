//
//  Prospects.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/26/22.
//

import SwiftUI

struct ProspectItem {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String
}

struct Prospect: View {
    let item: ProspectItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Icon badge
            Image(systemName: item.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(item.color)
                .padding(10)
                .background(item.color.opacity(0.12), in: Circle())

            // Title + subtitle
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("User Profile - Dark") {
    NavigationStack {
        let sampleItem = ProspectItem(symbol: "person.crop.circle", color: .blue, title: "John Appleseed", subtitle: "Premium Member")
        Prospect(item: sampleItem)
    }
    .preferredColorScheme(.dark)
}
