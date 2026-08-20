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
        } else if formData.label == CustomerLabels.userRole, !trimmedValue.isEmpty {
            let roleColor: Color = {
                switch trimmedValue.lowercased() {
                case "owner":    return .yellow
                case "admin":    return .indigo
                case "salesman": return .green
                case "viewer":   return .gray
                default:         return .orange
                }
            }()
            Text(trimmedValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(roleColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(roleColor.opacity(0.15).gradient, in: Capsule())
                .accessibilityLabel("Role: \(trimmedValue)")
        } else if formData.label == CustomerLabels.endDate, !trimmedValue.isEmpty {
            Text(trimmedValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.indigo)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.indigo.opacity(0.15).gradient, in: Capsule())
                .accessibilityLabel("Termination: \(trimmedValue)")
        } else if formData.label == "Salesperson", !trimmedValue.isEmpty {
            let isYes = trimmedValue.caseInsensitiveCompare("yes") == .orderedSame
            let spColor: Color = isYes ? .green : .red
            Text(trimmedValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(spColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(spColor.opacity(0.15).gradient, in: Capsule())
                .accessibilityLabel("Salesperson: \(trimmedValue)")
        } else if formData.label == CustomerLabels.salesman, !trimmedValue.isEmpty {
            Text(trimmedValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.teal)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.teal.opacity(0.15).gradient, in: Capsule())
                .accessibilityLabel("Salesman: \(trimmedValue)")
        } else if formData.label == CustomerLabels.employeeStatus {
            let isActive = trimmedValue.caseInsensitiveCompare("active") == .orderedSame
            let label = trimmedValue.isEmpty ? "Inactive" : formData.name
            let color: Color = isActive ? .green : .red
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.15).gradient, in: Capsule())
                .accessibilityLabel("Employee Status: \(label)")
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
            Text(trimmedValue.isEmpty ? "—" : formData.name)
                .font(.body)
                .foregroundStyle(trimmedValue.isEmpty ? Color.secondary : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
