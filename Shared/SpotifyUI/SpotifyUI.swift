//
//  SpotifyUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct SpotifyUI: View {
    
    @State var searchText = ""
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            SideTabViewUI()
            
            ScrollView(showsIndicators: false, content: {
                
                VStack(spacing: 15) {
                    
                    HStack(spacing: 15) {
                        
                        HStack(spacing: 15) {
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 25, height: 25)
                            
                            TextField("Search...", text: $searchText)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        
                        Button(action: {
                            
                        }, label: {
                            Image("taylor_swift_profile")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 45, height: 45)
                                .cornerRadius(10)
                        })
                    }
                    
                    Text("Recently Played")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)
                    
                    TabView {
                        
                        ForEach(recentlyPlayed) { item in
                            
                            ZStack(alignment: .bottomLeading) {
                                
                                Image(item.album_cover)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(20)
                                    //.padding(.horizontal)
                                    .overlay(
                                        LinearGradient(gradient: .init(colors: [Color.clear, Color.clear,Color.black]), startPoint: .top, endPoint: .bottom)
                                            .cornerRadius(20)
                                    )
                                
                                HStack(spacing: 15) {
                                    
                                    Button(action: {}, label: {
                                        Image(systemName: "play.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .padding(20)
                                            .background(Color(.red))
                                            .clipShape(Circle())
                                    })
                                    
                                    VStack(alignment: .leading, spacing: 5, content: {
                                        
                                        Text(item.album_name)
                                            .font(.title2)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.white)
                                        
                                        Text(item.album_author)
                                            .font(.none)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    })
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(height: 350)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .padding(.top, 20)
                    
                    Text("Genres")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 20, content: {
                        
                        ForEach(generes, id: \.self) { genre in
                            
                            Text(genre)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                    })
                    .padding(.top, 20)
                    
                    Text("Liked Songs")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10, content: {
                        
                        ForEach(likedSongs) { song in
                            
                            GeometryReader { proxy in
                                
                                Image(song.album_cover)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: proxy.frame(in: .global).width, height: 150)
                                    .cornerRadius(10)
                            }
                            .frame(height: 150)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    })
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
            })
            
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

struct SpotifyUI_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyUI()
            .preferredColorScheme(.dark)
    }
}

