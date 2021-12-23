//
//  ChatBubble.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/4/21.
//

import SwiftUI

struct ChatBubble: Shape {
    
    var myMsg : Bool
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, myMsg ? .bottomLeft : .bottomRight], cornerRadii: CGSize(width: 20, height: 20))
        
        return Path(path.cgPath)
    }
}
