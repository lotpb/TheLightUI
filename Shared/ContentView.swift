//
//  ContentView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    @State private var selection = 0
    
    var body: some View {
        
        //MainView()
        
        
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                MainMenuUI()
                    .tag(0)
                MainMessagesView()
                    .tag(1)
                WaveUI()
                    .tag(2)
                FurnitureUI()
                    .tag(3)
                WebUI()
                    .tag(4)
                TwitterUI()
                    .tag(5)
            }
            .tabViewStyle(DefaultTabViewStyle())
            Divider()
            TabBarView(selection: $selection)
        }
        .ignoresSafeArea(.all, edges: .top)
    }
}

@available(iOS 16.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TabBarView: View {
    @Binding var selection: Int
    @Namespace private var currentTab
    
    var body: some View {
        HStack {
            ForEach(tabs.indices, id: \.self) { index in
                GeometryReader { geometry in
                    VStack(spacing: 4) {
                        if selection == index {
                            Color(.label)
                                .frame(height: 2)
                                .offset(y: -1)
                                .matchedGeometryEffect(id: "currentTab", in: currentTab)
                        }
                        
                        if tabs[selection].label == "more" && tabs[index].label == "more" {
                            Image(systemName: tabs[index].image)
                                .font(.caption2)
                                .frame(height: 20)
                                .rotationEffect(.degrees(90))
                        } else {
                            Image(systemName: tabs[index].image)
                                .font(.caption2)
                                .frame(height: 20)
                                .rotationEffect(.degrees(0))
                        }
                        
                        Text(tabs[index].label)
                            .font(.system(size: 14))
                            .fixedSize()
                            .padding(.bottom, 5)
                    }
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(width: geometry.size.width / 2, height: 44, alignment: .bottom)
                    .padding(.horizontal)
                    .foregroundColor(selection == index ? Color.primary : .secondary)
                    .onTapGesture {
                        withAnimation {
                            selection = index
                        }
                    }
                }
                .frame(height: 44, alignment: .bottom)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(selection: Binding.constant(0))
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}

struct Tab {
    let image: String
    let label: String
}

let tabs = [
    Tab(image: "house.fill", label: "Home"),
    Tab(image: "message.fill", label: "Chat"),
    Tab(image: "wave.3.left", label: "Wave"),
    Tab(image: "cart", label: "Furn"),
    Tab(image: "network", label: "Web"),
    Tab(image: "brain.head.profile", label: "tweet"),
]
