//
//  UserDetail.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/30/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct UserFormUI: View {
    @State private var vm = MainMessagesViewModel()
    @State private var directions: [String] = []
    //@AppStorage(SettingsUI.latitudeKey) var latitude: Double = 0
    //@AppStorage(SettingsUI.longtitudeKey) var longtitude: Double = 0
    
    @State private var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2DMake(40.71, -74),
            span: MKCoordinateSpan.init(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    @State private var trackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            Map(coordinateRegion: $coordinateRegion, interactionModes: .zoom, showsUserLocation: true, userTrackingMode: $trackingMode)
                .ignoresSafeArea(edges: .top)
                .frame(height: 300)
                .cornerRadius(10)
                .shadow(radius: 4)

            //Image("taylor_swift_profile")
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
                .clipShape(Circle())//.clipped()
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
        UserFormUI()
            .preferredColorScheme(.dark)
    }
}
