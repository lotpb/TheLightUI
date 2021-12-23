//
//  MacbookPro.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 7/4/21.
//

import SwiftUI

struct MacbookPro: View {
    var body: some View {
        
        ZStack {
            
            Screen()
                .frame(width: 1265, height: 695)
            
            BottomViewMac()
                .frame(width: 1200, height: 1000)
            
        }
    }
}

struct MacbookPro_Previews: PreviewProvider {
    static var previews: some View {
        MacbookPro()
            .previewLayout(.fixed(width: 1500, height: 1000))
    }
}

struct Screen: View {
    
    var body: some View {
        
        ZStack {
            
            RoundedRectangle(cornerRadius: 30)
            
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(Color("Gray"), lineWidth: 6)
            
            VStack(spacing: 0) {
                
                Image("macOS")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1200, height: 590)
                    .cornerRadius(0)
                    .padding(.top, 40)
                    .padding(.bottom, 15)
                
                Rectangle()
                    .fill(.white.opacity(0.14))
                    .overlay(
                        Text("MacBook Pro")
                            .foregroundColor(.white)
                            .offset(y: -11)
                    )
            }
            
            HStack(spacing: 0) {
                
                ZStack {
                    
                    Color.gray.opacity(0.3)
                        .clipShape(Circle())
                        .frame(width: 10, height: 10)
                    
                    Color.black
                        .clipShape(Circle())
                        .frame(width: 3, height: 3)
                }
                
                Color.green.clipShape(Circle())
                    .frame(width: 6, height: 6)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(y: 17)
        }
    }
}

struct BottomViewMac: View {
    var body: some View {
        
        ZStack {
            
            ZStack {
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray) //fix color
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(.linearGradient(
                        .init(colors: getGradient()),
                        startPoint: .leading,
                        endPoint: .trailing))
                    .frame(width: 180)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(.linearGradient(
                        .init(colors: getGradient().reversed()),
                        startPoint: .leading,
                        endPoint: .trailing))
                    .frame(width: 180)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 25)
            .scaleEffect(0.7)
            
            CustomCornerMac(corners: [.bottomLeft, .bottomRight], radius: 20)
                .fill(Color("Gray1").opacity(0.5))
                .frame(height: 50)
                .overlay(
                
                    CustomCornerMac(corners: [.bottomLeft, .bottomRight], radius: 20)
                        .fill(.linearGradient(.init(colors: [
                            Color("gray1").opacity(0.4),
                            .black.opacity(0.2),
                            .black.opacity(0.6)
                        ]), startPoint: .top,
                            endPoint: .bottom))
                )
                .overlay(
                    
                    CustomCornerMac(corners: [.bottomLeft, .bottomRight], radius: 20)
                        .fill(.linearGradient(.init(colors: [
                            .black.opacity(0.2),
                            .black.opacity(0.1),
                            .clear
                        ]), startPoint: .top,
                            endPoint: .bottom))
                        .frame(height: 80)
                    
                        .rotation3DEffect(.init(degrees: 50), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: 0, perspective: 3)
                        .shadow(radius: 2)
                        .scaleEffect(1.0)
                        .offset(y: 50)
                )
                .scaleEffect(0.672)
                .rotation3DEffect(.init(degrees: -70), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: 1, perspective: 3)
                .offset(y: 15.5)
        }
        .scaleEffect(1.7)
        .overlay(
            
            ZStack {
            
            RoundedRectangle(cornerRadius: 100)
                .fill(.gray.opacity(0.4))
            
            let clearColor = Array(repeating: Color.clear, count: 12)
            
            let colors : [Color] = [
                
                .black.opacity(0.55),
                .black.opacity(0.25),
                .black.opacity(0.05)
            ]
            
            let gradient = colors + clearColor + colors.reversed()
            
            RoundedRectangle(cornerRadius: 100)
                .fill(.linearGradient(
                    .init(colors: gradient),
                    startPoint: .leading,
                    endPoint: .trailing))
            
            RoundedRectangle(cornerRadius: 100)
                .fill(.black.opacity(0.1))
        }
                .frame(width: 220, height: 35)
            
                .offset(y: -15)
                .clipped()
                .offset(y: 2)
        )
        .offset(y: 340)
    }
    
    func getGradient()->[Color] {
        
        let colors =
        [Color("Gray2"), Color("Gray1").opacity(0.7), Color("Gray2"), Color("Gray2"), Color("Gray2"), Color("Gray2")]
        
        return colors
    }
}

struct CustomCornerMac: Shape {
    
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        return Path(path.cgPath)
    }
}
