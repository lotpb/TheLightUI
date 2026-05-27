//
//  CustomCorner.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 6/16/21.
//
//  Updated by Xcode Assistant on 5/27/26: unify corner shapes, simplify API, add docs.
//

import SwiftUI

/// A SwiftUI `Shape` that rounds specific corners of a rectangle with a given radius.
///
/// Usage:
/// ```swift
/// Rectangle()
///     .fill(.blue)
///     .clipShape(CornerRadiusShape(corners: [.topLeft, .bottomRight], radius: 12))
/// ```
public struct CornerRadiusShape: Shape {
    /// The corners to round.
    public var corners: UIRectCorner
    /// The corner radius to apply.
    public var radius: CGFloat

    /// Creates a corner-radius shape.
    /// - Parameters:
    ///   - corners: The corners to round. Defaults to all corners.
    ///   - radius: The radius to apply to rounded corners.
    public init(corners: UIRectCorner = .allCorners, radius: CGFloat) {
        self.corners = corners
        self.radius = radius
    }

    public func path(in rect: CGRect) -> Path {
        Path.roundedCorners(in: rect, corners: corners, radius: radius)
    }
}

private extension Path {
    static func roundedCorners(in rect: CGRect, corners: UIRectCorner, radius: CGFloat) -> Path {
        // Use UIBezierPath to generate a CGPath for the requested corners and radius.
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
