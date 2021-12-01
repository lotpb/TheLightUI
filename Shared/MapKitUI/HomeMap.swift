//
//  Home.swift
//  TheLight2
//
//  Created by Peter Balsamo on 4/3/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI
import CoreLocation

struct HomeMap: View {
    @StateObject var mapData = MapViewModel()
    // Location Manager
    @State var locationMAnager = CLLocationManager()
    @State var width = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            
            // MapView
            MapViewUI()
                // using it as environment object so that it can be used in subView
                .environmentObject(mapData)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search", text: $mapData.searchTxt)
                            .colorScheme(.light)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.white)
                    
                    // Displaying Results
                    if !mapData.places.isEmpty && mapData.searchTxt != "" {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(mapData.places) { place in
                                    Text(place.placemark.name ?? "")
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading)
                                        .onTapGesture {
                                            mapData.selectPlace(place: place)
                                        }
                                    
                                    Divider()
                                }
                            }
                            .padding(.top)
                        }
                        .background(Color.white)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack {
                    Button(action: mapData.updateMapType) {
                        Image(systemName: mapData.mapType == .standard ? "network" : "map")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: mapData.focusLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(Color.primary)
                            .clipShape(Circle())
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                
                //                VStack {
                //                    Button(action: mapData.focusLocation) {
                //                        Image(systemName: "location.fill")
                //                            .font(.title2)
                //                            .padding(10)
                //                            .background(Color.primary)
                //                            .clipShape(Circle())
                //                    }
                //
                //                    Button(action: mapData.updateMapType) {
                //                        Image(systemName: mapData.mapType == .standard ? "network" : "map")
                //                            .font(.title2)
                //                            .padding(10)
                //                            .background(Color.primary)
                //                            .clipShape(Circle())
                //                    }
                //                }
                //                .frame(width: width / 2, alignment: .leading)
                //                .padding()
            }
        }
        .onAppear {
            // Setting Delegate
            locationMAnager.delegate = mapData
            locationMAnager.requestWhenInUseAuthorization()
        }
        // Permission Denied Alert
        .alert(isPresented: $mapData.permissionDenied) {
            Alert(title: Text("Permission Denied"), message: Text("Please Enable Permission In App Settings"), dismissButton: .default(Text("Go to Settings"), action: {
                // Redirecting User to Settings
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
        }
        .onChange(of: mapData.searchTxt) { (value) in
            // Searching Places
            
            // You can use your own delay time to avoid Continuos Search Request
            let delay = 0.3
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if value == mapData.searchTxt {
                    // Search
                    self.mapData.searchQuery()
                }
            }
        }
    }
}

struct HomeMap_Previews: PreviewProvider {
    static var previews: some View {
        HomeMap()
    }
}
