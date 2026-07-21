//
//  LeadDetailFieldRow.swift
//  TheLightUI
//

import SwiftUI

struct LeadDetailFieldRow: View {
    let formData: CustomerDetailField

    var body: some View {
        HStack(spacing: 12) {
            Text(formData.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)

            Spacer()

            valueContent
        }
    }

    @ViewBuilder
    private var valueContent: some View {
        let trimmedValue = formData.name.trimmingCharacters(in: .whitespacesAndNewlines)

        if formData.label == CustomerLabels.rating,
           let rating = Int(trimmedValue),
           rating > 0 {
            HStack(spacing: 2) {
                ForEach(1...min(rating, 5), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.body)
                        .foregroundStyle(.yellow)
                }
            }
            .accessibilityLabel("Rating")
            .accessibilityValue("\(min(rating, 5)) out of 5")
        } else if formData.label == CustomerLabels.rating, trimmedValue.isEmpty {
            Text("No ratings")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            Text(formData.name)
                .font(.body)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
