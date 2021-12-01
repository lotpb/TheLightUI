//
//  3DCarousel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct CarouselView: View {
    
    @State var currentTab = "taylor_swift_profile"
    
    var body: some View {
        ZStack {
            
            GeometryReader { proxy in
                
                let size = proxy.size
                
                Image(currentTab)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(1)
            }
            .ignoresSafeArea()
            .overlay(.ultraThinMaterial)
            .colorScheme(.dark)
            
            TabView(selection: $currentTab) {
                
                ForEach(1...4, id: \.self) { index in
                    
                    CarouselBodyView(index: index)
                    
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

@available(iOS 15.0, *)
struct CarouselView_Previews: PreviewProvider {
    static var previews: some View {
        CarouselView()
    }
}
