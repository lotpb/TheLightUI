//
//  RecenterButton.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI


struct RecenterButton: View {
    
    let onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Label("Re-center", systemImage: "triangle")
        }
        .padding(10)
        .foregroundColor(.white)
        .background(Color.accentColor)
        .cornerRadius(12)
    }
}

struct RecenterButton_Previews: PreviewProvider {
    static var previews: some View {
        RecenterButton { }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
