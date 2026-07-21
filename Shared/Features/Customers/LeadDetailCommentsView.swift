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
                // When the popover adapts to a sheet on iPhone, keep it at half height.
                .presentationDetents([.medium, .large])
        }
    }
}

private struct LeadDetailCommentsEditor: View {
    @Binding var detail: CustomerItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.title3)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)

            Text("Comments:")
                .font(.headline)

            TextEditor(text: $detail.comments)
                .font(.headline)
                .foregroundStyle(Color.primary)
        }
        .padding()
        // Ideal size drives the iPad popover; the flexible bounds let the
        // iPhone sheet adaptation fill its detent instead of clipping.
        .frame(minWidth: 320, idealWidth: 380, maxWidth: .infinity, minHeight: 240, idealHeight: 280, maxHeight: .infinity)
    }
}
