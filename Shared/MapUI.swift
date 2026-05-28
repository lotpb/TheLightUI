//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import CoreLocationUI
import SwiftUI

struct MapUI: View {
    @StateObject private var manager = LocationManager()
    @State private var directions: [String] = []
    @State private var offset: CGFloat = 0
    @State private var isDragged = false
    @State private var mapstreet: String
    @State private var mapcity: String
    @State private var mapstate: String
    @State private var mapzip: String

    @State var travelTime: Double
    @State var distance: Double

    init(
        mapstreet: String = "",
        mapcity: String = "",
        mapstate: String = "",
        mapzip: String = "",
        travelTime: Double,
        distance: Double
    ) {
        self._mapstreet = State(initialValue: mapstreet)
        self._mapcity = State(initialValue: mapcity)
        self._mapstate = State(initialValue: mapstate)
        self._mapzip = State(initialValue: mapzip)
        self._travelTime = State(initialValue: travelTime)
        self._distance = State(initialValue: distance)
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            MapButtonView(manager: manager, directions: $directions)
            bottomSheetLayer
        }
        .onAppear {
            manager.startUpdating()
        }
        .onDisappear {
            manager.stopUpdating()
        }
    }

    private var mapLayer: some View {
        RouteMapView(
            manager: manager,
            travelTime: $travelTime,
            distance: $distance,
            directions: $directions,
            mapstreet: $mapstreet,
            mapcity: $mapcity,
            mapstate: $mapstate,
            mapzip: $mapzip,
            region: $manager.region,
            mapType: manager.mapType
        )
        .ignoresSafeArea(.all, edges: .all)
        .gesture(mapDragGesture)
        .overlay(recenterButton, alignment: .center)
    }

    private var mapDragGesture: some Gesture {
        DragGesture()
            .onChanged { _ in
                isDragged = true
                manager.stopUpdating()
            }
    }

    @ViewBuilder
    private var recenterButton: some View {
        if isDragged {
            LocationButton(.shareCurrentLocation) {
                manager.requestLocation()
                isDragged = false
            }
            .padding()
        }
    }

    private var bottomSheetLayer: some View {
        GeometryReader { reader in
            VStack {
                BottomSheetUI(
                    locationManager: manager,
                    offset: $offset,
                    value: expandedOffset(for: reader),
                    travelTime: $travelTime,
                    distance: $distance
                )
                .offset(y: reader.frame(in: .global).height - 60)
                .offset(y: offset)
                .gesture(bottomSheetDragGesture(reader: reader))
            }
        }
    }

    private func bottomSheetDragGesture(reader: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.86, blendDuration: 0.2)) {
                    updateBottomSheetOffset(value: value, reader: reader)
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82, blendDuration: 0.2)) {
                    settleBottomSheet(value: value, reader: reader)
                }
                impact(.light)
            }
    }

    private func updateBottomSheetOffset(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader)
        let dragStartedLow = value.startLocation.y > reader.frame(in: .global).midY
        let dragStartedHigh = value.startLocation.y < reader.frame(in: .global).midY

        if dragStartedLow, value.translation.height < 0, offset > expandedOffset {
            offset = value.translation.height
        }

        if dragStartedHigh, value.translation.height > 0, offset < 0 {
            offset = expandedOffset + value.translation.height
        }
    }

    private func settleBottomSheet(value: DragGesture.Value, reader: GeometryProxy) {
        let expandedOffset = expandedOffset(for: reader)
        let midpoint = reader.frame(in: .global).midY
        let dragStartedLow = value.startLocation.y > midpoint
        let dragStartedHigh = value.startLocation.y < midpoint

        if dragStartedLow {
            offset = -value.translation.height > midpoint ? expandedOffset : 0
        }

        if dragStartedHigh {
            offset = value.translation.height < midpoint ? expandedOffset : 0
        }
    }

    private func expandedOffset(for reader: GeometryProxy) -> CGFloat {
        -reader.frame(in: .global).height + 150
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct MapUI_Previews: PreviewProvider {
    static var previews: some View {
        MapUI(travelTime: 0.00, distance: 0.00)
            .preferredColorScheme(.dark)
    }
}
