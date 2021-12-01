//
//  Gradient.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/8/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct GradientUI: View {
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
//
//    @State var timeRemaining: String = ""
//
//    let futureDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
//
//    func updateTimeRemaining() {
//
//    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1))]),
                center: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/,
                startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/,
                endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
                .ignoresSafeArea()
            
            
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.system(size: 100, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .padding()
        }
        .onReceive(timer, perform: { _ in
            //updateTimeRemaining()
        })
        
    }
}

@available(iOS 15.0, *)
struct GradientUI_Previews: PreviewProvider {
    static var previews: some View {
        GradientUI()
        .previewInterfaceOrientation(.portrait)
    }
}
