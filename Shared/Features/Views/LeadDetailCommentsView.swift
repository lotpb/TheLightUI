//
//  LeadDetailCommentsView.swift
//  TheLightUI
//

import SwiftUI

struct LeadDetailCommentsView: View {
    @Binding var detail: CustomerItem
    @Binding var showPopover: Bool
    let accentColor: Color

    private var hasComments: Bool {
        !detail.comments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                Text("Comments")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Read more") { showPopover = true }
                    .buttonStyle(.bordered)
                    .tint(accentColor)
                    .disabled(!hasComments)
            }
            .foregroundStyle(accentColor)

            Text(CustomerLabels.customerNews)
                .foregroundStyle(Color.secondary)
                .lineLimit(2)
                .font(.footnote)

            Text(detail.comments)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .popover(isPresented: $showPopover) {
            LeadDetailCommentsEditor(detail: $detail)
        }
    }
}

private struct LeadDetailCommentsEditor: View {
    @Binding var detail: CustomerItem

    private var formattedDate: String {
        Date().formatted(date: .complete, time: .omitted)
    }

    var body: some View {
        VStack {
            Text(formattedDate)
                .font(.title2)
                .padding(.bottom, 15)
                .lineLimit(1)
                .minimumScaleFactor(0.1)

            Text("Comments:")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            TextEditor(text: $detail.comments)
                .font(.headline)
                .foregroundStyle(Color.primary)
        }
        .frame(width: 380, height: 260)
    }
}
