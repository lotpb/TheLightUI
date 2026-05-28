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
        return CustomCorners(corners: corners, radius: 20).path(in: rect)
    }
}
