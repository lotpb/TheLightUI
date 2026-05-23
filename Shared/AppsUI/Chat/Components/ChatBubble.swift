//
//  ChatBubble.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/4/21.
//

import SwiftUI

struct ChatBubble: Shape {
    
    let isCurrentUserMessage: Bool
    
    func path(in rect: CGRect) -> Path {
        let corners: UIRectCorner = [
            .topLeft,
            .topRight,
            isCurrentUserMessage ? .bottomLeft : .bottomRight
        ]
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}
