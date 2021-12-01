//
//  UserDetail.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/30/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
//import MapKit

struct UserDetail: View {
    //@EnvironmentObject var modelData: ModelData
     //var landmark: Landmark
    
    @StateObject var mapData = MapViewModel()
    @State private var directions: [String] = []

//     var landmarkIndex: Int {
//         modelData.landmarks.firstIndex(where: { $0.id == landmark.id })!
//     }
    
    var body: some View {
        ScrollView {
            MapView(directions: $directions)
                .ignoresSafeArea(edges: .top)
                .frame(height: 300)

            Image("taylor_swift_profile")
                .resizable()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(y: -130)
                .padding(.bottom, -130)

            VStack(alignment: .leading) {
                Text("Peter Balsamo")
                    .font(.title)
                    .foregroundColor(.primary)

                HStack {
                    Text("Massapequa")
                    Spacer()
                    Text("New York")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Divider()

                Text("President")
                    .font(.title2)
                Text("I am the owner of the company")
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserDetail_Previews: PreviewProvider {
    static var previews: some View {
        UserDetail()
    }
}
