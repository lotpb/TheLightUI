//
//  Loader.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/30/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

///LoginView
struct Loader : UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<Loader>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.startAnimating()
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Loader>) {
        
    }
}
