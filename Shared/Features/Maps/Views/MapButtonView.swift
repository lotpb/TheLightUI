//
//  MapButtonView.swift
//  TheLightUI
//

import CoreLocationUI
import SwiftUI
import MapKit

struct MapButtonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject var manager: LocationManager
    @StateObject private var viewModel = MainMessagesViewModel()

    @Binding var directions: [String]
    @Binding var mapType: MKMapType
    @State private var showDirections = false
    @State private var lastNon3DMapType: MKMapType = .standard

    private var speedText: String {
        let metersPerSecond = max(manager.location?.speed ?? 0.0, 0.0)
        let speed = 2.23694 * metersPerSecond
        return String(format: "Speed: %.0f", speed)
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
        .task { await viewModel.fetchCurrentUser() }
    }

    private var leadingControls: some View {
        VStack {
            dismissButton
            Spacer()
            directionsButton
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 05)
    }

    private var trailingControls: some View {
        VStack {
            mapTypeButton
            threeDButton
            Spacer()
            locationButton
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 05)
    }

    private var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            ProfileAvatarImage(urlString: viewModel.chatUser?.profileImageUrl)
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
        .foregroundColor(.primary)
        .opacity(directions.isEmpty ? 0.45 : 1)
        .disabled(directions.isEmpty)
        .accessibilityLabel("Show Directions")
    }

    private var mapTypeButton: some View {
        Button {
            manager.stopFollowingLocation()
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
        .foregroundColor(.primary)
        .accessibilityLabel("Toggle Map Type")
    }

    private var threeDButton: some View {
        Button {
            manager.stopFollowingLocation()
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
        .foregroundColor(.primary)
        .accessibilityLabel(mapType == .hybridFlyover ? "Switch to 2D Mode" : "Switch to 3D Mode")
    }
    
    private var locationButton: some View {
        Button {
            manager.requestLocation()
        } label: {
            circularIcon("location.fill")
        }
        .foregroundColor(.primary)
        .accessibilityLabel("Current Location")
    }

    private var speedBadge: some View {
        VStack {
            Text(speedText)
                .foregroundColor(.primary)
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
                .foregroundColor(.primary)

            Divider()
                .background(Color.secondary)

            List(directions, id: \.self) { instruction in
                HStack {
                    Image(systemName: directionsIcon(instruction))
                    Text(instruction)
                        .padding()
                }
            }
            .foregroundColor(Color.white)
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
        if instruction.contains("destination") {
            return "mappin.circle.fill"
        } else if instruction.contains("right") {
            return "arrow.turn.up.right"
        } else if instruction.contains("left") {
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

