//
//  BottomSheetShareButton.swift
//  TheLightUI
//

import SwiftUI

struct BottomSheetShareButton: View {
    let url: URL?
    let accessibilityLabel: String

    var body: some View {
        if let url {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        }
    }
}
