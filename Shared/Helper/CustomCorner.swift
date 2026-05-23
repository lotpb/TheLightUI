//
//  CustomCorner.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 6/16/21.
//

import SwiftUI

struct CustomCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path.roundedCorners(in: rect, corners: corners, radius: radius)
    }
}

struct CustomShape: Shape {
    var corner: UIRectCorner
    var radii: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path.roundedCorners(in: rect, corners: corner, radius: radii)
    }
}

private extension Path {
    static func roundedCorners(in rect: CGRect, corners: UIRectCorner, radius: CGFloat) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
