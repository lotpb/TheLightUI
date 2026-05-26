//
//  LandMarkListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI


struct LandMarkListView: View {
    
    let landMarks: [LandMark]
    let index: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if landMarks.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(landMarks.enumerated()), id: \.element.id) { itemIndex, landMark in
                        LandMarkRowView(landMark: landMark, number: itemIndex + 1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 64, height: 64)
                .background(.regularMaterial, in: Circle())

            Text("No places found")
                .font(.headline)

            Text("Try searching for a different category or location.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct LandMarkRowView: View {
    let landMark: LandMark
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(landMark.name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(landMark.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !landMark.displayPhone.isEmpty {
                    Label(landMark.displayPhone, systemImage: "phone.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
    }
}
