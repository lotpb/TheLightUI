//
//  CustomCorner.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 6/16/21.
//

import SwiftUI

///LoginView, ShapUI, BottomActionSheet, LeadDetailUI
struct CustomCorners: Shape {

    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {

        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))

        return Path(path.cgPath)
    }
}

struct CustomShape: Shape {

    var corner : UIRectCorner
    var radii : CGFloat

    func path(in rect: CGRect) -> Path {

        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corner, cornerRadii: CGSize(width: radii, height: radii))

        return Path(path.cgPath)
    }
}
