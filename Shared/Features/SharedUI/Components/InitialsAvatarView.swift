//
//  InitialsAvatarView.swift
//  TheLightUI
//

// Circular monogram avatar showing a person's initials, used where no profile photo exists.

import SwiftUI

struct InitialsAvatarView: View {
    let firstName: String
    let lastName: String
    var size: CGFloat = 88

    private var initials: String {
        [firstName, lastName]
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray3), Color(.systemGray)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if initials.isEmpty {
                // Generic person symbol when no name is available yet.
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size, height: size)
        // Decorative: the surrounding UI carries the person's name for assistive tech.
        .accessibilityHidden(true)
    }
}

#Preview("Initials Avatar") {
    VStack(spacing: 20) {
        InitialsAvatarView(firstName: "Peter", lastName: "Balsamo")
        InitialsAvatarView(firstName: "Janet", lastName: "", size: 60)
        InitialsAvatarView(firstName: "", lastName: "", size: 44)
    }
    .padding()
}
