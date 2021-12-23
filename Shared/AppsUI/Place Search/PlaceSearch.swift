//
//  PlaceSearch.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI
import MapKit


enum DisplayType {
    case list, map
}

struct PlaceSearch: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: PlaceListViewModel = PlaceListViewModel()
    @StateObject var locationManager = LocationManager()
    
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var searchText: String = ""
    @State private var displayType: DisplayType = .map
    @State private var isDragged: Bool = false
    let index: Int
    
    private func getRegion() -> Binding<MKCoordinateRegion> {
        guard let coordinate = viewModel.currentLocation else {
            return .constant(MKCoordinateRegion.defaultRegion)
        }
        return .constant(
            MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        )
    }
    
    
    var body: some View {
        NavigationView {
            VStack {
                LandMarkCategoryView { selectedCategory in
                    viewModel.searchLandmarks(selectedCategory)
                }
                .padding(.horizontal, 8)
                
                Picker(selection: $displayType, label: Text("Select")) {
                    Text("Map").tag(DisplayType.map)
                    Text("List").tag(DisplayType.list)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 700).clipped()
                
                switch displayType {
                case .list:
                    LandMarkListView(landMarks: viewModel.landMarks, index: index)
                    
                case .map:
                    Map(
                        coordinateRegion: getRegion(),
                        interactionModes: .all,
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: viewModel.landMarks,
                        annotationContent: { LandMark in
                            MapAnnotation(coordinate: LandMark.coordinate) {
                                //Image("mappin").foregroundColor(.red)
                                MapAnnotationView()
                                    .scaleEffect( 0.7)
                            }
                        }
                    )
                        .cornerRadius(10)
                        .padding(.top, 5)
                        .gesture(
                            DragGesture()
                                .onChanged({ value in
                                    isDragged = true
                                })
                        )
                        .overlay(
                            isDragged ?
                            AnyView(RecenterButton {
                                locationManager.startUpdating()
                                isDragged = false
                                locationManager.stopUpdating()
                            }.padding())
                            : AnyView(EmptyView()),
                            alignment: .bottom
                        )
                    
                }
            }
            .onAppear {
                locationManager.stopUpdating()
            }
            .onDisappear {
                locationManager.stopUpdating()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { newsearch in
                // get all land marks
                viewModel.searchLandmarks(searchText)
            }
            
            .navigationTitle("Search Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

struct PlaceSearch_Previews: PreviewProvider {
    static let index = 1
    static var previews: some View {
        PlaceSearch( index: index)
    }
}
