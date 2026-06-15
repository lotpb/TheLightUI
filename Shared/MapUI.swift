//
//  MapUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import CoreLocationUI
import SwiftUI
import MapKit

struct MapUI: View {
    @StateObject private var manager = LocationManager()
    @State private var directions: [String] = []
    @State private var offset: CGFloat = 0
    @State private var bottomSheetDragStartOffset: CGFloat?
    @State private var isDragged = false
    @State private var is3DEnabled = false
    @State private var mapType: MKMapType = .standard
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
            MapButtonView(manager: manager, directions: $directions, mapType: $mapType)
                .zIndex(1)
            bottomSheetLayer
                .zIndex(3)
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
            mapType: $mapType
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

    private func toggle3D() {
        is3DEnabled.toggle()
        // Switch to a 3D flyover map type when available; fall back to standard for 2D
        if is3DEnabled {
            mapType = .hybridFlyover
        } else {
            mapType = .standard
        }
        impact(.light)
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
                updateBottomSheetOffset(value: value, reader: reader)
            }
            .onEnded { value in
                let startingOffset = bottomSheetDragStartOffset ?? offset
                let targetOffset = nearestBottomSheetOffset(
                    to: startingOffset + value.predictedEndTranslation.height,
                    reader: reader
                )
                bottomSheetDragStartOffset = nil

                withAnimation(.spring(response: 0.34, dampingFraction: 0.88, blendDuration: 0.12)) {
                    offset = targetOffset
                }
                impact(.light)
            }
    }

    private func updateBottomSheetOffset(value: DragGesture.Value, reader: GeometryProxy) {
        if bottomSheetDragStartOffset == nil {
            bottomSheetDragStartOffset = offset
        }

        let startingOffset = bottomSheetDragStartOffset ?? offset
        offset = clampedBottomSheetOffset(startingOffset + value.translation.height, reader: reader)
    }

    private func nearestBottomSheetOffset(to proposedOffset: CGFloat, reader: GeometryProxy) -> CGFloat {
        bottomSheetSnapOffsets(for: reader)
            .min { abs($0 - proposedOffset) < abs($1 - proposedOffset) } ?? 0
    }

    private func clampedBottomSheetOffset(_ proposedOffset: CGFloat, reader: GeometryProxy) -> CGFloat {
        min(max(proposedOffset, expandedOffset(for: reader)), collapsedOffset)
    }

    private func bottomSheetSnapOffsets(for reader: GeometryProxy) -> [CGFloat] {
        [expandedOffset(for: reader), halfExpandedOffset(for: reader), collapsedOffset]
    }

    private func expandedOffset(for reader: GeometryProxy) -> CGFloat {
        -reader.frame(in: .global).height + 150
    }

    private func halfExpandedOffset(for reader: GeometryProxy) -> CGFloat {
        -(reader.frame(in: .global).height * 0.5) + 60
    }

    private var collapsedOffset: CGFloat { 0 }

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

