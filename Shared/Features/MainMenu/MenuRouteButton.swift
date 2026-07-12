//
//  MenuRouteButton.swift
//  TheLightUI
//

import SwiftUI

protocol MenuRouteDisplaying {
    var title: String { get }
    var subtitle: String? { get }
    var systemImage: String { get }
    var iconColor: Color { get }
}

struct MenuRouteButton: View {
    @AppStorage(SettingsUI.color) private var themeColorSetting: Int?
    @AppStorage(SettingsUI.useThemeMenuIconsKey) private var useThemeMenuIcons = false
    var title: String
    var subtitle: String? = nil
    var systemImage: String = "mappin.and.ellipse"
    var iconColor: Color = .accentColor
    var isCompact = false
    var action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String = "mappin.and.ellipse",
        iconColor: Color = .accentColor,
        isCompact: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.isCompact = isCompact
        self.action = action
    }

    init(item: MenuRouteDisplaying, action: @escaping () -> Void) {
        self.init(
            title: item.title,
            subtitle: item.subtitle,
            systemImage: item.systemImage,
            iconColor: item.iconColor,
            isCompact: true,
            action: action
        )
    }

    private var iconSize: CGFloat {
        isCompact ? 30 : 36
    }

    private var verticalPadding: CGFloat {
        isCompact ? 4 : 8
    }

    private var resolvedIconColor: Color {
        useThemeMenuIcons ? AppTheme.accentColor(for: themeColorSetting) : iconColor
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 12 : 14) {
                RoundedRectangle(cornerRadius: isCompact ? 7 : 8)
                    .fill(resolvedIconColor)
                    .frame(width: iconSize, height: iconSize)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: isCompact ? 16 : 19, weight: .medium))
                            .foregroundStyle(.white)
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

#Preview {
    List {
        Section {
            MenuRouteButton(
                title: "Expenses",
                subtitle: "Track spending",
                systemImage: "creditcard.fill",
                iconColor: .green,
                isCompact: true
            ) { }
            MenuRouteButton(
                title: "Tip Calculator",
                subtitle: "Split a bill",
                systemImage: "receipt.fill",
                iconColor: .orange,
                isCompact: true
            ) { }
        } header: {
            Text("Apps")
        }
    }
    .listStyle(.insetGrouped)
}
