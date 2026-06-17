//
//  MenuRouteButton.swift
//  TheLightUI
//

import SwiftUI

protocol MenuRouteDisplaying {
    var title: String { get }
    var subtitle: String? { get }
    var systemImage: String { get }
}

struct MenuRouteButton: View {
    var title: String
    var subtitle: String? = nil
    var systemImage: String = "mappin.and.ellipse"
    var tint: Color = .accentColor
    var isCompact = false
    var action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String = "mappin.and.ellipse",
        tint: Color = .accentColor,
        isCompact: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.isCompact = isCompact
        self.action = action
    }

    init(item: MenuRouteDisplaying, tint: Color, action: @escaping () -> Void) {
        self.init(
            title: item.title,
            subtitle: item.subtitle,
            systemImage: item.systemImage,
            tint: tint,
            isCompact: true,
            action: action
        )
    }

    private var iconSize: CGFloat {
        isCompact ? 32 : 40
    }

    private var verticalPadding: CGFloat {
        isCompact ? 4 : 8
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 10 : 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .imageScale(isCompact ? .medium : .large)
                }

                VStack(alignment: .leading, spacing: isCompact ? 1 : 2) {
                    Text(title)
                        .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(isCompact ? .caption : .subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(isCompact ? .caption : .body)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, verticalPadding)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        if let subtitle {
            return "\(title), \(subtitle)"
        }
        return title
    }
}
