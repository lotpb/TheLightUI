//
//  MapAnnotationView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI

struct MapAnnotationView: View {
    let number: Int?
    let isSelected: Bool
    let accentColor: Color
    
    private enum Layout {
        static let markerSize: CGFloat = 34
        static let pointerSize: CGFloat = 13
        static let pointerOffset: CGFloat = -3.5
    }
    
    init(
        number: Int? = nil,
        isSelected: Bool = false,
        accentColor: Color = Color("AccentColor")
    ) {
        self.number = number
        self.isSelected = isSelected
        self.accentColor = accentColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            markerIcon
            pointerIcon
        }
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
    
    private var markerIcon: some View {
        ZStack {
            Circle()
                .fill(markerColor)
                .frame(width: Layout.markerSize, height: Layout.markerSize)
            
            if let number {
                Text("\(number)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            } else {
                Image(systemName: "mappin")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
    }
    
    private var pointerIcon: some View {
        Image(systemName: "triangle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(markerColor)
            .frame(width: Layout.pointerSize, height: Layout.pointerSize)
            .rotationEffect(.degrees(180))
            .offset(y: Layout.pointerOffset)
            .padding(.bottom, 40)
    }
    
    private var markerColor: Color {
        isSelected ? .yellow : accentColor
    }
    
    private var accessibilityText: String {
        if let number {
            return "Map annotation \(number)"
        }
        
        return "Map annotation"
    }
}

#Preview("Map Annotation") {
    VStack(spacing: 30) {
        MapAnnotationView()
        MapAnnotationView(number: 1, isSelected: true)
    }
    .padding()
    .preferredColorScheme(.dark)
}
