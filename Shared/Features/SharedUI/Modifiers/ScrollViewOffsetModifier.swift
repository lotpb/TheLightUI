//
//  ScrollViewOffsetModifier.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

/// A view modifier that publishes a view's position along a chosen axis anchor.
struct ScrollViewOffsetModifier: ViewModifier {
    var anchor: ScrollOffsetAnchor = .top
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    // Use Color.clear so layout is unaffected, and send the value via preference.
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: anchor.value(from: proxy.frame(in: .global))
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

// MARK: - Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Prefer the most recent value; if multiple geometry readers update in the same pass,
        // take the latest reported value.
        value = nextValue()
    }
}

// MARK: - Anchor
enum ScrollOffsetAnchor: CaseIterable, Sendable {
    case top, bottom, leading, trailing

    fileprivate func value(from frame: CGRect) -> CGFloat {
        switch self {
        case .top: return frame.minY
        case .bottom: return frame.maxY
        case .leading: return frame.minX
        case .trailing: return frame.maxX
        }
    }

    @available(*, deprecated, renamed: "top")
    static var Top: ScrollOffsetAnchor { .top }
}

// MARK: - Convenience API
extension View {
    /// Reads the view's position for the given anchor into the provided binding.
    func scrollOffset(_ offset: Binding<CGFloat>, anchor: ScrollOffsetAnchor = .top) -> some View {
        modifier(ScrollViewOffsetModifier(anchor: anchor, offset: offset))
    }
}
