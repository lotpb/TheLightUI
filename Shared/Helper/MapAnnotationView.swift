//
//  LocationMapAnnotationView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI

struct MapAnnotationView: View {
    let accentColor = Color("AccentColor")
    
    //var index: Int
    //@Binding var isSelected: Int
    
    var body: some View {
        VStack(spacing: 0) {
            
//            Circle()
//                .foregroundColor(isSelected == index ? .yellow: .red)
//            .frame(width: 25, height: 25)
//            .overlay(Text("\(index + 1)").foregroundColor(.white))
            
            
            Image(systemName: "1.circle.fill") //mappin.and.ellipse
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .font(.headline)
                .foregroundColor(.white)
                .padding(2)
                .background(accentColor)
                .clipShape(Circle())
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(accentColor)
                .frame(width: 13, height: 13)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3.5)
                .padding(.bottom, 40)
            
        }
    }
}

struct LocationMapAnnotationView_Previews: PreviewProvider {
    //static var index = 0
    static var previews: some View {
        
        //Color.black.ignoresSafeArea()
        MapAnnotationView()
    }
}
