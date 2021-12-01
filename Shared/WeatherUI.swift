//
//  WeatherUI.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 6/16/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct WeatherUI: View {
    var body: some View {
        ZStack {
            
            GeometryReader { proxy in
                
                Image("sky")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .ignoresSafeArea()
            .overlay(.ultraThinMaterial)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack {
                    
                }
                .padding(.top, 25)
                .padding([.horizontal, .bottom])
            }
        }
    }
}

@available(iOS 15.0, *)
struct WeatherUI_Previews: PreviewProvider {
    static var previews: some View {
        WeatherUI()
    }
}

//struct CustomStackView<Title: View, Content: View>: View {
//    var titleView: Title
//    var contentView: Content
//    
//    init(@ViewBuilder titleView: @escaping ()->Title, @ViewBuilder content: @escaping ()->Content) {
//        
//        self.contentView = contentView()
//        self.titleView = titleView()
//    }
//}
