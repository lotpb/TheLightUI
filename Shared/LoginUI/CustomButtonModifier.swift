//
//  CustomBottonModifier.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct CustomButtonModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        return content
            .foregroundColor(.white)
            .padding(.vertical)
            .padding(.horizontal, 35)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color("yellow-light"), Color("yellow")]), startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
    }
}
