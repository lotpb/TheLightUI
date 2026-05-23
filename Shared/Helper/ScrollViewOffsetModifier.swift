//
//  ScrollViewOffsetModifier.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

struct ScrollViewOffsetModifier: ViewModifier {
    var anchorPoint: ScrollOffsetAnchor = .top
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: value(from: proxy.frame(in: .global))
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
    
    private func value(from frame: CGRect) -> CGFloat {
        switch anchorPoint {
        case .top:
            return frame.minY
        case .bottom:
            return frame.maxY
        case .leading:
            return frame.minX
        case .trailing:
            return frame.maxX
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum ScrollOffsetAnchor {
    case top
    case bottom
    case leading
    case trailing
    
    @available(*, deprecated, renamed: "top")
    static var Top: ScrollOffsetAnchor { .top }
}

typealias Anchor = ScrollOffsetAnchor
