//
//  Loader.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 3/30/21.
//

import SwiftUI

struct Loader: UIViewRepresentable {
    var style: UIActivityIndicatorView.Style = .large
    var color: UIColor?
    var isAnimating = true
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.color = color
        updateAnimationState(for: indicator)
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.style = style
        uiView.color = color
        updateAnimationState(for: uiView)
    }
    
    private func updateAnimationState(for indicator: UIActivityIndicatorView) {
        if isAnimating {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
    }
}

#Preview("Loader") {
    Loader()
        .frame(width: 80, height: 80)
}
