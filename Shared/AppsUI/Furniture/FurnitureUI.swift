//
//  FurnitureUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/28/21.
//

import SwiftUI

struct FurnitureUI: View {
    @State private var search: String = ""
    @State private var selectedIndex: Int = 1
    //let maxWidthForIpad: CGFloat = 700
    
    private let categories = ["All", "Chair", "Sofa", "Lamp", "Kitchen", "Table"]
    var body: some View {
        NavigationView {
            ZStack {
                CustomColor.linenColor
                //Color(#colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.937254902, alpha: 1))
                    .ignoresSafeArea()
                
                ScrollView (showsIndicators: false) {
                    VStack (alignment: .leading) {
                        AppBarView()
                        TagLineView()
                            .padding()
                        SearchAndScanView(search: $search)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(0 ..< categories.count, id: \.self) { i in
                                    Button(action: {selectedIndex = i}) {
                                        CategoryView(isActive: selectedIndex == i, text: categories[i])
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        Text("Popular")
                            .font(.custom("PlayfairDisplay-Bold", size: 24))
                            .padding(.horizontal)
                            .foregroundColor(.black)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack (spacing: 0) {
                                ForEach(0 ..< 4) { i in
                                    NavigationLink(
                                        destination: FurnitureDetail(),
                                        label: {
                                            ProductCardView(image: Image("chair_\(i+1)"), size: 210)
                                        })
                                        .navigationBarHidden(true)
                                        .foregroundColor(.black)
                                }
                                .padding(.leading)
                            }
                        }
                        .padding(.bottom)
                        
                        Text("Best")
                            .font(.custom("PlayfairDisplay-Bold", size: 24))
                            .padding(.horizontal)
                            .foregroundColor(.black)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack (spacing: 0) {
                                ForEach(0 ..< 4) { i in
                                    ProductCardView(image: Image("chair_\(4-i)"), size: 180)
                                }
                                .foregroundColor(.black)
                                .padding(.leading)
                            }
                        }
                    }
                }
                VStack {
                    Spacer()
                    BottomNavBarView()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .frame(maxWidth: .infinity)
//        .navigationBarTitle("") //this must be empty
//        .navigationBarHidden(true)
//        .navigationBarBackButtonHidden(true)
    }
        
}

struct FurnitureUI_Previews: PreviewProvider {
    static var previews: some View {
        FurnitureUI().preferredColorScheme(.dark)
        
        FurnitureUI()
    }
}



struct AppBarView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "person")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10.0)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image("taylor_swift_profile")
                    .resizable()
                    .frame(width: 42, height: 42)
                    .cornerRadius(10.0)
            }
        }
        .padding(.horizontal)
    }
}

struct TagLineView: View {
    var body: some View {
        Text("Find the \nBest ")
            .font(.custom("PlayfairDisplay-Regular", size: 28))
            .foregroundColor(.black)
            + Text("Furniture!")
            .font(.custom("PlayfairDisplay-Bold", size: 28))
            .fontWeight(.bold)
            .foregroundColor(.black)
    }
}

struct SearchAndScanView: View {
    @Binding var search: String
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "bell").padding(.trailing, 8)
                TextField("Search Furniture", text: $search)
            }
            .padding(.all, 15)
            .background(Color.white)
            .cornerRadius(10.0)
            .padding(.trailing, 8)
            
            Button(action: {}) {
                Image(systemName: "bolt")
                    .padding()
                    .background(Color(.white))
                    .cornerRadius(10.0)
            }
        }
        .foregroundColor(.black)
        .padding(.horizontal)
    }
}

struct CategoryView: View {
    let isActive: Bool
    let text: String
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundColor(isActive ? Color(.black) : Color.black.opacity(0.5))
            if (isActive) { Color(.white)
                .frame(width: 15, height: 2)
                .clipShape(Capsule())
            }
        }
        .padding(.trailing)
    }
}

struct ProductCardView: View {
    let image: Image
    let size: CGFloat
    
    var body: some View {
        VStack {
            image
                .resizable()
                .frame(width: size, height: 200 * (size/210))
                .cornerRadius(20.0)
            Text("Luxury Swedian chair").font(.title3).fontWeight(.bold)
            
            HStack (spacing: 2) {
                ForEach(0 ..< 5) { item in
                    Image(systemName: "star").font(.caption2)
                }
                Spacer()
                Text("$1299")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .frame(width: size)
        .padding()
        .background(Color.white)
        .cornerRadius(20.0)
        
    }
}


struct BottomNavBarView: View {
    var body: some View {
        HStack {
            BottomNavBarItem(image: Image(systemName: "star"), action: {})
            BottomNavBarItem(image: Image(systemName: "bell"), action: {})
            BottomNavBarItem(image: Image(systemName: "car"), action: {})
            BottomNavBarItem(image: Image(systemName: "mic"), action: {})
        }
        .padding()
        .background(Color.white)
        .foregroundColor(.black)
        .clipShape(Capsule())
        .padding(.horizontal)
        .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 2, y: 6)
    }
}

struct BottomNavBarItem: View {
    let image: Image
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            image
                .frame(maxWidth: .infinity)
        }
    }
}
