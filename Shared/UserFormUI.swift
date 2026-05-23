//
//  UserFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 4/30/21.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI

struct UserFormUI: View {
    @StateObject private var viewModel = MainMessagesViewModel()
    
    @State private var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.71, longitude: -74),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var trackingMode: MapUserTrackingMode = .follow
    
    private let profileName = "Peter Balsamo"
    private let profileCity = "Delray Beach"
    private let profileState = "Florida"
    private let profileTitle = "President"
    private let profileDescription = "I am the owner of the company"
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            profileMap
            profileImage
            profileDetails
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var profileMap: some View {
        Map(
            coordinateRegion: $coordinateRegion,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: $trackingMode
        )
        .ignoresSafeArea(edges: .top)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: 4)
    }
    
    private var profileImage: some View {
        WebImage(url: URL(string: viewModel.chatUser?.profileImageUrl ?? ""))
            .placeholder {
                Image("taylor_swift_profile")
                    .resizable()
                    .scaledToFill()
            }
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .offset(y: -130)
            .padding(.bottom, -130)
    }
    
    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profileName)
                .font(.title)
                .foregroundColor(.primary)
            
            HStack {
                Text(profileCity)
                Spacer()
                Text(profileState)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Divider()
            
            Text(profileTitle)
                .font(.title2)
            Text(profileDescription)
        }
        .padding()
    }
}

#Preview("User Profile - Dark") {
    NavigationStack {
        UserFormUI()
    }
    .preferredColorScheme(.dark)
}
