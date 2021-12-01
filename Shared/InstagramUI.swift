//
//  InstagramUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct InstagramUI: View {
    
    @State var selectedTab: String = "square.grid.3x3"
    @Namespace var animation
    @Environment(\.colorScheme) var scheme
    @State var topHeaderOffset: CGFloat = 0
    
    var body: some View {
        
        VStack {
            
            HStack(spacing: 15) {
                
                Button(action: {}, label: {
                    Text("_Kavsoft")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                })
                
                Spacer()
                
                Button(action: {}, label: {
                    Image(systemName: "plus.app")
                        .font(.title)
                        .foregroundColor(.primary)
                })
                
                Button(action: {}, label: {
                    Image(systemName: "line.horizontal.3")
                        .font(.title)
                        .foregroundColor(.primary)
                })
                
                
            }
            .padding([.horizontal, .top])
            .overlay(
                
                GeometryReader { proxy -> Color in
                    
                    let minY = proxy.frame(in: .global).minY
                    
                    DispatchQueue.main.sync {
                        if topHeaderOffset == 0 {
                            topHeaderOffset = minY
                        }
                    }
                    
                    return Color.clear
                }
                .frame(width: 0, height: 0)
                ,alignment: .bottom
            )
            
            ScrollView(.vertical, showsIndicators: false, content : {
                
                VStack {
                    
                    Divider()
                    
                    HStack {
                        
                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                            
                            Image("taylor_swift_profile")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .padding(2)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .offset(x: 5, y: 5)
                                    ,alignment:  .bottomTrailing
                                )
                        })
                        
                        VStack {
                            Text("199")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Posts")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("1,129")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Followers")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text("13")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Following")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    VStack(alignment: .leading, spacing: 4, content: {
                        Text("Kavsoft . iOS $ SwiftUI Dev")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Video Creator")
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Text("ftfkftdky kutfufkufkuulf lyuflul ulglggglggl glglgi7glglig iggliglggllgli ggukggykgkgkugku")
                        
                        Link(destination: URL(string: "https://www.apple.com")!, label: {
                            Text("Link")
                        })
                    })
                    .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        
                        Button(action: {}, label: {
                            Text("Edit Profile")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray)
                                )
                        })
                        
                        Button(action: {}, label: {
                            Text("Promotion's")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray)
                                )
                        })
                    }
                    .padding([.horizontal, .top])
                    
                    ScrollView(.horizontal, showsIndicators: false, content: {
                        
                        HStack(spacing: 15) {
                            
                            Button(action: {}, label: {
                                VStack {
                                    
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                        .padding(18)
                                        .background(Circle().stroke(Color.gray))
                                    
                                    Text("New")
                                        .foregroundColor(.primary)
                                }
                            })
                        }
                        .padding([.horizontal, .top])
                    })
                    
                    GeometryReader { proxy -> AnyView in
                        
                        let minY = proxy.frame(in: .global).minY
                        
                        let offset = minY - topHeaderOffset
                        
                        print(offset)
                        
                        return AnyView (
                            
                            HStack(spacing: 0) {
                                
                                TabBarButtonUI(image: "square.grid.3x3", isSystemImage: true, animation: animation, selectedTab: $selectedTab)
                                
                                TabBarButtonUI(image: "film", isSystemImage: false, animation: animation, selectedTab: $selectedTab)
                                
                                TabBarButtonUI(image: "person.crop.square", isSystemImage: true, animation: animation, selectedTab: $selectedTab)
                            }
                            .frame(height: 50, alignment: .bottom)
                            .background(scheme == .dark ? Color.black : Color.white)
                            .offset(y: offset < 0 ? -offset : 0)
                        )
                    }
                    
                    ZStack {
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2, content: {
                            
                            ForEach(1...30, id: \.self) { index in
                                
                                GeometryReader { proxy in
                                    let width = proxy.frame(in: .global).width
                                    
                                    ImageView(index: index, width: width)
                                }
                                .frame(height: 120)
                            }
                        })
                    }
                }
                .frame(height: 70)
                .zIndex(4)
            })
        }
    }
}

struct InstagramUI_Previews: PreviewProvider {
    static var previews: some View {
        InstagramUI()
    }
}

struct ImageView: View {
    
    var index: Int
    var width: CGFloat
    
    var body: some View {
        
        VStack {
            
            let imageName = index > 10 ? index - (10 * (index / 10))  == 0 ? 10 :
                index - (10 * (index / 10)) : index
            
            Image("post\(imageName)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: 120)
                .cornerRadius(0)
        }
        
    }
}

struct TabBarButtonUI: View {
    
    var image: String
    var isSystemImage: Bool
    var animation: Namespace.ID
    @Binding var selectedTab: String
    
    var body: some View {
        
        Button(action: {
            withAnimation(.easeOut) {
                selectedTab = image
            }
        }, label: {
            
            VStack(spacing: 12) {
                
                (
                    isSystemImage ? Image(systemName: image) : Image(image)
                )
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(selectedTab == image ? .primary : .gray)
                
                ZStack {
                    
                    if selectedTab == image {
                        Rectangle()
                            .fill(Color.primary)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                    else {
                        Rectangle()
                            .fill(Color.clear)
                    }
                    
                }
                .frame(height: 1)
            }
        })
    }
}
