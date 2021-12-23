//
//  Stacks.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/18/22.
//

import SwiftUI


struct StacksView: View {
    
    @Environment(\.dismiss) var dismiss
    let maxWidthForIpad: CGFloat = 700
    @State private var searchText = ""
    //if UIDevice.current.userInterfaceIdiom == .phone {
    //var color: Color = ColorOptions.random()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 35) {
                    
                    VStack(alignment: .leading) {
                        Text("Your top genres")
                            .padding(.top,30)
                        
                        GeometryReader { geo in
                            //row 1
                            HStack {
                                ZStack(alignment: .bottomTrailing) {
                                    ZStack(alignment: .topLeading) {
                                        ZStack {
                                            
                                            Rectangle()
                                                .fill(Color.brown)
                                                .cornerRadius(7)
                                                .frame(width: geo.size.width * 0.475, height: 100)
                                        }
                                        
                                        
                                        Text("Furniture")
                                            .foregroundColor(.white)
                                            .padding()
                                            //.zIndex(0)
                                    }
                                    
                                    Image("chair_1")
                                        .resizable()
                                        .scaledToFill()
                                        .cornerRadius(5)
                                        .frame(width: 75, height: 75)
                                        .rotationEffect(.degrees(25))
                                        .offset(x: 18, y: 0)
                                        //.zIndex(1)
                                    
                                    
                                }.clipped()
                                
                                
                                Spacer()
                                
                                ZStack(alignment: .bottomTrailing) {
                                    ZStack(alignment: .topLeading) {
                                        Rectangle()
                                            .fill(Color.purple)
                                            .cornerRadius(7)
                                            .frame(width: geo.size.width * 0.475, height: 100)
                                        
                                        Text("Freaks")
                                        //.bold()
                                            .foregroundColor(.white)
                                            .padding()
                                    }
                                    
                                    Image("ZuckBuddist")
                                        .resizable()
                                        .scaledToFill()
                                        .cornerRadius(5)
                                        .frame(width: 75, height: 75)
                                        .rotationEffect(.degrees(25))
                                        .offset(x: 21, y: 0)
                                }.clipped()
                            }
                        }
                        
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Featured podcast categories")
                            .padding(.top, 30)
                        
                        GeometryReader { geo in
                            //row 2
                        HStack {
                            ZStack(alignment: .bottomTrailing) {
                                ZStack(alignment: .topLeading) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.pink)
                                            .cornerRadius(7)
                                            .frame(width: geo.size.width * 0.475, height: 100)
                                    }
                                    
                                    Text("Podcast New\nReleases")
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                
                                Image("taylor_swift_profile")
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(5)
                                    .frame(width: 75, height: 75)
                                    .rotationEffect(.degrees(25))
                                    .offset(x: 18, y: 0)
                                
                            }.clipped()
                            
                            Spacer()
                            
                            ZStack(alignment: .bottomTrailing) {
                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .cornerRadius(7)
                                        .frame(width: geo.size.width * 0.475, height: 100)
                                    
                                    Text("True Crime\nScene")
                                    //.bold()
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                
                                Image("chair_2")
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(5)
                                    .frame(width: 75, height: 75)
                                    .rotationEffect(.degrees(25))
                                    .offset(x: 18, y: 0)
                                
                            }.clipped()
                        }
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Browse all")
                            .padding(.top,30)
                        
                        GeometryReader { geo in
                        //row 3
                        HStack {
                            ZStack(alignment: .bottomTrailing) {
                                ZStack(alignment: .topLeading) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.red)
                                            .cornerRadius(7)
                                            .frame(width: geo.size.width * 0.475, height: 100)
                                    }
                                    
                                    Text("Products")
                                    //.bold()
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                
                                Image("profile-rabbit-toy")
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(5)
                                    .frame(width: 75, height: 75)
                                    .rotationEffect(.degrees(25))
                                    .offset(x: 18, y: 0)
                            }.clipped()
                            
                            Spacer()
                            
                            ZStack(alignment: .bottomTrailing) {
                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .fill(Color.indigo)
                                        .cornerRadius(7)
                                        .frame(width: geo.size.width * 0.475, height: 100)
                                    
                                    Text("Made for\n you")
                                    //.bold()
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                
                                Image("IMG_3408")
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(5)
                                    .frame(width: 75, height: 75)
                                    .rotationEffect(.degrees(25))
                                    .offset(x: 18, y: 0)
                                
                            }.clipped()
                        }
                        }
                    }
                    
                    Spacer()
                }
                .font(.headline.bold())
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Label("Close", systemImage: "xmark.circle.fill")
                        }
                    }
                    
                    //                    ToolbarItem(placement: .navigationBarTrailing) {
                    //                        Button(action: {
                    //                            dismiss()
                    //                        }) {
                    //                            Label("Close", systemImage: "camera.fill")
                    //                        }
                    //
                    //                    }
                    //
                    //                    ToolbarItem(placement: .automatic) {
                    //                        Button(action: {
                    //                            dismiss()
                    //                        }) {
                    //                            Label("Close", systemImage: "bell.fill")
                    //                        }
                    //
                    //                    }
                }
                
            }
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
        }
        .frame(maxWidth: maxWidthForIpad)
    }
}

struct Stacks_Previews: PreviewProvider {
    static var previews: some View {
        StacksView().preferredColorScheme(.dark)
    }
}
