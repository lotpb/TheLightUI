//
//  Loader.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 3/30/21.
//

import SwiftUI

struct Loader: View {
    var isAnimating: Bool = true
    var tint: Color? = nil
    var scale: CGFloat = 1.0

    var body: some View {
        Group {
            if isAnimating {
                if let tint {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(tint)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
        .scaleEffect(scale)
        .accessibilityLabel("Loading")
    }
}

#Preview("Loader") {
    Loader(isAnimating: true, tint: .accentColor, scale: 1.1)
        .frame(width: 80, height: 80)
}
