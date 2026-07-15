//
//  MapButtonView.swift
//  TheLightUI
//

import CoreLocationUI
import SwiftUI
import MapKit

struct MapButtonView: View {
    @Environment(\.dismiss) private var dismiss
    var manager: LocationManager
    let profileImageURL: String?

    @Binding var directions: [MapRouteStep]
    @Binding var travelTime: Double
    @Binding var distance: Double
    @Binding var mapType: MKMapType
    @State private var showDirections = false
    @State private var showLocationPermissionExplanation = false
    @State private var lastNon3DMapType: MKMapType = .standard
    @State private var geofenceDraft: GeofenceDraft?

    private let geofenceManager = GeofenceManager.shared

    // BottomSheetUI's collapsed bar peeks 80pt on iPad (vs 16 on iPhone),
    // so lift the bottom buttons higher there to keep them clear of it.
    private var bottomButtonPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 114 : 50
    }

    private var speedText: String {
        MapFormat.speed(manager.location?.speed ?? 0)
    }

    var body: some View {
        HStack {
            leadingControls
            Spacer()
            speedBadge
            Spacer()
            trailingControls
        }
        .padding()
        .sheet(isPresented: $showDirections) {
            directionsSheet
        }
        .sheet(item: $geofenceDraft) { draft in
            GeofenceEditorSheet(center: draft.center)
        }
        .confirmationDialog(
            "Use your current location to center the map and calculate nearby directions.",
            isPresented: $showLocationPermissionExplanation,
            titleVisibility: .visible
        ) {
            Button("Continue") { manager.resumeFollowingLocation() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var leadingControls: some View {
        VStack {
            dismissButton
            Spacer()
            directionsButton
                .padding(.bottom, bottomButtonPadding)
        }
        .padding(.horizontal, 05)
    }

    private var trailingControls: some View {
        VStack {
            mapTypeButton
            threeDButton
            geofenceButton
            Spacer()
            locationButton
                .padding(.bottom, bottomButtonPadding)
        }
        .padding(.horizontal, 05)
    }

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            ProfileAvatarImage(urlString: profileImageURL)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.top, 2)
        }
    }

    private var directionsButton: some View {
        Button {
            showDirections.toggle()
        } label: {
            circularIcon("mappin.and.ellipse")
        }
        .foregroundStyle(Color.primary)
        .opacity(directions.isEmpty ? 0.45 : 1)
        .disabled(directions.isEmpty)
        .accessibilityLabel("Show Directions")
    }

    private var mapTypeButton: some View {
        Button {
            manager.pauseFollowingLocation()
            // Toggle between standard and satellite; remember last non-3D type
            if mapType == .hybridFlyover {
                // If currently 3D, switch to last non-3D selection
                mapType = lastNon3DMapType
            } else {
                lastNon3DMapType = (mapType == .standard) ? .satellite : .standard
                mapType = lastNon3DMapType
            }
        } label: {
            circularIcon(mapType == .standard ? "network" : "map")
        }
        .foregroundStyle(Color.primary)
        .accessibilityLabel("Toggle Map Type")
    }

    private var threeDButton: some View {
        Button {
            manager.pauseFollowingLocation()
            if mapType == .hybridFlyover {
                // Return to the last remembered non-3D map type
                mapType = lastNon3DMapType
            } else {
                // Enter 3D mode and remember current non-3D type
                lastNon3DMapType = mapType
                mapType = .hybridFlyover
            }
        } label: {
            circularText(mapType == .hybridFlyover ? "2D" : "3D")
        }
        .foregroundStyle(Color.primary)
        .accessibilityLabel(mapType == .hybridFlyover ? "Switch to 2D Mode" : "Switch to 3D Mode")
    }

    private var geofenceButton: some View {
        Menu {
            Button {
                geofenceDraft = GeofenceDraft(center: manager.region.center)
            } label: {
                Label("Add Geofence Here", systemImage: "plus.circle")
            }
            .disabled(!geofenceManager.canAddGeofence)

            if !geofenceManager.geofences.isEmpty {
                Menu {
                    ForEach(geofenceManager.geofences) { geofence in
                        Button(role: .destructive) {
                            Task { await geofenceManager.removeGeofence(geofence) }
                        } label: {
                            Text(geofence.id)
                        }
                    }
                } label: {
                    Label("Remove Geofence", systemImage: "minus.circle")
                }

                Button(role: .destructive) {
                    Task { await geofenceManager.removeAllGeofences() }
                } label: {
                    Label("Remove All Geofences", systemImage: "trash")
                }
            }
        } label: {
            circularIcon("circle.dashed")
        }
        .foregroundStyle(Color.primary)
        .accessibilityLabel("Geofences")
    }

    private var locationButton: some View {
        Button {
            if manager.locationStatus == .notDetermined {
                showLocationPermissionExplanation = true
            } else {
                manager.resumeFollowingLocation()
            }
        } label: {
            circularIcon("location.fill")
        }
        .foregroundStyle(Color.primary)
        .accessibilityLabel("Current Location")
    }

    private var speedBadge: some View {
        VStack {
            Text(speedText)
                .foregroundStyle(Color.primary)
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 120, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
            Spacer()
        }
    }

    private var directionsSheet: some View {
        VStack(spacing: 0) {
            Text("Directions")
                .font(.headline)
                .bold()
                .padding()
                .foregroundStyle(Color.primary)

            Divider()
                .background(Color.secondary)

            routeSummaryTable

            routeStepsTable
        }
    }

    private var routeSummaryTable: some View {
        List {
            Section {
                routeDistanceCell
            } header: {
                Text("Distance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(height: 96)
        .scrollDisabled(true)
        .foregroundStyle(Color.white)
    }

    private var routeStepsTable: some View {
        List {
            Section {
                ForEach(directions) { step in
                    directionStepRow(step)
                }
            } header: {
                Text("Steps")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .foregroundStyle(Color.white)
        
    }

    private func directionStepRow(_ step: MapRouteStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: directionsIcon(step.instructions))
                .frame(width: 24)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.instructions)
                    .font(.headline.weight(.semibold))
                    .lineLimit(nil)

                Text(step.distanceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 12)

            Text(step.travelTimeText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }

    private var routeDistanceCell: some View {
        HStack(spacing: 12) {
            Image(systemName: "map")
                .frame(width: 24)

            Text(MapFormat.distance(distance))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 12)

            Text(MapFormat.travelTime(travelTime))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.trailing)
        }
    }

    private func circularIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .modifier(CircularIconStyle())
    }

    private func circularText(_ text: String) -> some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))

            Text(text)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(width: 50, height: 50)
    }

    private func directionsIcon(_ instruction: String) -> String {
        let lowercasedInstruction = instruction.lowercased()

        if lowercasedInstruction.contains("destination") {
            return "mappin.circle.fill"
        } else if lowercasedInstruction.contains("right") {
            return "arrow.turn.up.right"
        } else if lowercasedInstruction.contains("left") {
            return "arrow.turn.up.left"
        } else {
            return "arrow.up"
        }
    }
}

private struct CircularIconStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .padding(10)
            .background(.thinMaterial)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
    }
}
