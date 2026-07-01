//
//  CarouselBodyView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

@available(iOS 18.0, *)
struct CarouselBodyView: View {
    let page: CarouselPage
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cardSize = CGSize(width: size.width - 8, height: size.height / 1.2)
            
            ZStack {
                Image(page.resolvedImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack {
                    headerContent
                    Spacer(minLength: 0)
                    profileContent
                }
                .padding(20)
            }
            .frame(width: cardSize.width, height: cardSize.height)
            .frame(width: size.width, height: size.height)
            .rotation3DEffect(
                .degrees(progress(in: size.width) * 90),
                axis: (x: 0, y: 1, z: 0),
                anchor: offset > 0 ? .leading : .trailing,
                anchorZ: 0,
                perspective: 0.6
            )
        }
        .tag(page.id)
        .modifier(ScrollViewOffsetModifier(anchor: .leading, offset: $offset))
    }
    
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(page.title)
                .font(.title2.bold())
                .kerning(1.5)
            
            Text(page.subtitle)
                .kerning(1.2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var profileContent: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack(spacing: 15) {
                Image(CarouselPage.fallbackImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 55, height: 55)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(page.profileName)
                        .font(.title2.bold())
                    
                    Text(page.profileSubtitle)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.black)
            }
            
            HStack {
                ForEach(page.stats) { stat in
                    StatView(value: stat.value, label: stat.label)
                }
            }
            .foregroundStyle(.black)
        }
        .padding(20)
        .padding(.horizontal, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: 4))
    }
    
    private func progress(in width: CGFloat) -> CGFloat {
        width > 0 ? -offset / width : 0
    }
}

@available(iOS 18.0, *)
private struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 18.0, *)
#Preview("Carousel Body - Dark") {
    CarouselBodyView(page: CarouselPage.pages[0])
        .preferredColorScheme(.dark)
}
