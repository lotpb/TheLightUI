//
//  CarouselSliderUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/15/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct CarouselSliderUI: View {
    var body: some View {
        HomeUi()
    }
}

struct CarouselSliderUI_Previews: PreviewProvider {
    static var previews: some View {
        CarouselSliderUI()
    }
}

struct HomeUi: View {
    
    @State var currentIndex : Int = 1
    
    var body: some View {
        
        VStack {
            
            TabView(selection: $currentIndex) {
                
                ForEach(1...3, id: \.self) { index in
                    
                    GeometryReader{ proxy -> AnyView in
                        
                        let minX = proxy.frame(in: .global).minX
                        
                        let width = UIScreen.main.bounds.width
                        
                        let progress = -minX / (width * 2)
                        
                        var scale = progress > 0 ? 1 - progress : 1 + progress
                        
                        scale = scale < 0.7 ? 0.7 : scale
                        
                        return AnyView (
                            
                            VStack {
                                //Image("Reel\(index)")
                                Image("profile-rabbit-toy")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.horizontal, 70)
                                
                                Text("TheLight")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                                
                                Text("Company to expand to a new web advertising directive this week.")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                            .scaleEffect(scale)
                        )
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            CustomTabIndicator(count: 3, current: $currentIndex)
                .padding(.vertical)
                .padding(.top)
            
            VStack(spacing: 15) {
                
                Button(action: {}, label: {
                    HStack {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                        
                        Text("Sign up with Apple ")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity,alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black)
                            .overlay (
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    )
                })
                
                Button(action: {}, label: {
                    HStack {
                        Image(systemName: "applelogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(.red)
                        
                        Text("Sign up with Google ")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity,alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay (
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    )
                })
                
                Button(action: {}, label: {
                    HStack {
                        Image(systemName: "envelope")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(.black)
                        
                        Text("Sign up with Email  ")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity,alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay (
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    )
                })
                
                HStack {
                    
                    Text("already have an Account?")
                        .foregroundColor(.white)
                    
                    Button(action: {}, label: {
                        Text("login")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .underline(true, color: Color.white)
                    })
                }
                .padding(.top, 30)
            }
            .padding()
        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background(Color(.systemTeal).ignoresSafeArea())
    }
}

struct CustomTabIndicator: View {
    
    var count: Int
    @Binding var current: Int
    
    var body: some View {
        
        HStack {
            ForEach(0..<count,id: \.self) { index in
                
                ZStack {
                    
                    if (current - 1) == index {
                        
                        Circle()
                            .fill(Color.black)
                    }
                    else {
                        
                        Circle()
                            .fill(Color.white)
                            .overlay(
                        
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5))
                    }
                }
                .frame(width: 10, height: 10)
            }
        }
    }
}
