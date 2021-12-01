//
//  ScrollViewOffsetModifier.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

struct ScrollViewOffsetModifier: ViewModifier {
    
    var anchorPoint: Anchor = .Top
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        
        content
            .overlay(
                
                GeometryReader { proxy -> Color in
                
                let frame = proxy.frame(in: .global)
                
                DispatchQueue.main.async {
                    
                    switch anchorPoint {
                    case .Top:
                        offset = frame.minY
                    case .bottom:
                        offset = frame.maxY
                    case .leading:
                        offset = frame.minX
                    case .trailing:
                        offset = frame.maxX
                    }
                }
                
                return Color.clear
            })
    }
}

enum Anchor {
    case Top
    case bottom
    case leading
    case trailing
}
