import SwiftUI

/// A shape that rounds selected corners of a rectangle with the given radius.
struct CustomCorners: Shape {
    let corners: UIRectCorner
    let radius: CGFloat

    init(corners: UIRectCorner = .allCorners, radius: CGFloat) {
        self.corners = corners
        self.radius = radius
    }

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
