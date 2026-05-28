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

            Text(formData.name)
                .font(.body)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
