//
//  BlurView123.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/25/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
///LoginView, MapUI, BottomActionSheet, TwitterUI
struct BlurViewUI: UIViewRepresentable {

    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {

        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))

        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {

    }

}
