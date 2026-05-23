//
//  WaveUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 6/13/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, *)
struct WaveUI: View {
    
    @State private var toggle = false
    
    var body: some View {
        
        ZStack {
            
            WaveFormUI(color: .purple.opacity(0.8), amplify: 150, isReversed: false)
            
            WaveFormUI(color: (toggle ? Color.purple : Color.cyan).opacity(0.6), amplify: 140, isReversed: true)
            
            VStack {
                HStack {
                    
                    Text("Wave's")
                        .font(.largeTitle.bold())
                    
                    Spacer()
                    
                    Toggle(isOn: $toggle) {
                        Image(systemName: "eyedropper.halffull")
                            .font(.title2)
                    }
                    .toggleStyle(.button)
                    .tint(.purple)
                }
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

@available(iOS 15.0, *)
struct WaveFormUI: View {
    
    let color: Color
    let amplify: CGFloat
    let isReversed: Bool
    
    var body: some View {
        
        TimelineView(.animation) { timeLine in
            
            Canvas { context, size in
                
                let timeNow = timeLine.date.timeIntervalSinceReferenceDate
                
                let angle = timeNow.remainder(dividingBy: 2)
                
                let offset = angle * size.width
                
                context.translateBy(x: isReversed ? -offset : offset, y: 0)
                
                context.fill(wavePath(size: size), with: .color(color))
                
                context.translateBy(x: -size.width, y: 0)
                
                context.fill(wavePath(size: size), with: .color(color))
                
                context.translateBy(x: size.width * 2, y: 0)
                
                context.fill(wavePath(size: size), with: .color(color))
            }
        }
    }
    
    private func wavePath(size: CGSize) -> Path {
        Path { path in
            let midHeight = size.height / 2
            let width = size.width
            
            path.move(to: CGPoint(x: 0, y: midHeight))
            path.addCurve(
                to: CGPoint(x: width, y: midHeight),
                control1: CGPoint(x: width * 0.4, y: midHeight + amplify),
                control2: CGPoint(x: width * 0.65, y: midHeight - amplify)
            )
            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
        }
    }
    
}

@available(iOS 15.0, *)
struct WaveUI_Previews: PreviewProvider {
    static var previews: some View {
        WaveUI()
    }
}
