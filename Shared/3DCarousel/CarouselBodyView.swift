//
//  CarouselBodyView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct CarouselBodyView: View {
    
    var index: Int
    @State var offset: CGFloat = 0
    
    var body: some View {
        
        GeometryReader { proxy in
            
            let size = proxy.size
            
            ZStack {
                
                //Image("p\(index)")
                Image("taylor_swift_profile")
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fill)
                    .frame(width: size.width - 8, height: size.height / 1.2)
                    .cornerRadius(12)
                
                VStack {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Human Integration Supervisor")
                            .font(.title2.bold())
                            .kerning(1.5)
                        
                        Text("The world's largest collection of animal facts, pictures and more!")
                            .kerning(1.2)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                    .padding(.top)
                    
                    Spacer(minLength: 0)
                    
                    VStack(alignment: .leading, spacing: 30) {
                        
                        HStack(spacing: 15) {
                            
                            Image("taylor_swift_profile")
                                .resizable()
                                .aspectRatio(contentMode: ContentMode.fill)
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 6) {
                                
                                Text("Peter")
                                    .font(.title2.bold())
                                
                                Text("Apple Sheep")
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.black)
                        }
                        
                        HStack {
                            
                            VStack {
                                
                                Text("1303")
                                    .font(.title2.bold())
                                
                                Text("Posts")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack {
                                
                                Text("3103")
                                    .font(.title2.bold())
                                
                                Text("Followers")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack {
                                
                                Text("1603")
                                    .font(.title2.bold())
                                
                                Text("Following")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(.black)
                    }
                    .padding(20)
                    .padding(.horizontal, 10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 4))
                }
                .padding(20)
            }
            .frame(width: size.width - 8, height: size.height / 1.2)
            .frame(width: size.width, height: size.height)
        }
        .tag("p\(index)")
        
        .modifier(ScrollViewOffsetModifier(anchorPoint: .leading, offset: $offset))
        //.overlay(Text("\(offset)").foregroundColor(.white))
        .rotation3DEffect(.init(degrees: getProgress() * 90), axis: (x: 0, y: 1, z: 0), anchor: offset > 0 ? .leading : .trailing, anchorZ: 0, perspective: 0.6)
    }
    
    func getProgress()->CGFloat {
        let progress = -offset / UIScreen.main.bounds.width
        
        return progress
    }
}

@available(iOS 15.0, *)
struct CarouselBodyView_Previews: PreviewProvider {
    static var previews: some View {
        CarouselView()
    }
}
