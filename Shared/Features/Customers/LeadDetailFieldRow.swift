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
        } else if formData.label == CustomerLabels.photo {
            let hasPhoto = !trimmedValue.isEmpty && trimmedValue.lowercased() != "none"
            HStack(spacing: 6) {
                Image(systemName: hasPhoto ? "photo.fill" : "camera.badge.ellipsis")
                    .font(.body)
                    .foregroundStyle(hasPhoto ? Color.primary : Color.secondary)
                Text(hasPhoto ? trimmedValue : "Add Photo")
                    .font(.body)
                    .foregroundStyle(hasPhoto ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityLabel(hasPhoto ? "Photo: \(trimmedValue)" : "Add Photo")
        } else if formData.label == CustomerLabels.callback {
            let isYes = trimmedValue.caseInsensitiveCompare("YES") == .orderedSame
            HStack(spacing: 6) {
                Image(systemName: "phone.arrow.up.right.fill")
                    .font(.body)
                    .foregroundStyle(isYes ? Color.green : Color.secondary)
                Text(trimmedValue.isEmpty ? "No" : formData.name)
                    .font(.body)
                    .foregroundStyle(isYes ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityLabel("Callback: \(trimmedValue.isEmpty ? "No" : formData.name)")
        } else {
            Text(formData.name)
                .font(.body)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
