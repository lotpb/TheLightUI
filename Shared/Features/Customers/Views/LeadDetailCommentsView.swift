//
//  LeadDetailCommentsView.swift
//  TheLightUI
//

import SwiftUI

struct LeadDetailCommentsView: View {
    @AppStorage("color") private var color: Int?

    @Binding var detail: CustomerItem
    @Binding var showPopover: Bool

    private var accentColor: Color {
        color == 0 ? Color.purple : Color.orange
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
            }
            .foregroundStyle(accentColor)

            Text(CustomerLabels.customerNews)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .font(.footnote)

            Text(detail.comments)
                .foregroundColor(.primary)
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: Date())
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
                .foregroundColor(.primary)
        }
        .frame(width: 380, height: 260)
    }
}
