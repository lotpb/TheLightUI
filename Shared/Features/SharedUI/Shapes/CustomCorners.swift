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
        Path(
            roundedRect: rect,
            cornerRadii: RectangleCornerRadii(
                topLeading: radius(for: .topLeft),
                bottomLeading: radius(for: .bottomLeft),
                bottomTrailing: radius(for: .bottomRight),
                topTrailing: radius(for: .topRight)
            ),
            style: .continuous
        )
    }

    private func radius(for corner: UIRectCorner) -> CGFloat {
        corners.contains(corner) ? radius : 0
    }
}
