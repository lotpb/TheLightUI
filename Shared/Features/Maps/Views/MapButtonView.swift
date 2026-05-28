//
//  MapButtonView.swift
//  TheLightUI
//

import CoreLocationUI
import SwiftUI

struct MapButtonView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openURL) private var openURL
    @ObservedObject var manager: LocationManager

    @Binding var directions: [String]
    @State private var showDirections = false

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
    }

    private var leadingControls: some View {
        VStack {
            dismissButton
            Spacer()
            directionsButton
                .padding(.bottom, 60)
        }
        .padding(.horizontal)
    }

    private var trailingControls: some View {
        VStack {
            mapTypeButton
            Spacer()
            locationButton
                .padding(.bottom, 60)
        }
        .padding(.horizontal)
    }

    private var dismissButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image("taylor_swift_profile")
                .resizable()
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
    }

    private var mapTypeButton: some View {
        Button {
            manager.stopFollowingLocation()
            manager.updateMapType()
        } label: {
            circularIcon(manager.mapType == .standard ? "network" : "map")
        }
    }

    @ViewBuilder
    private var locationButton: some View {
        if #available(iOS 26.0, *) {
            Button {
                manager.requestLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Current Location")
        } else {
            Button {
                manager.requestLocation()
            } label: {
                circularIcon("location.fill")
            }
            .accessibilityLabel("Current Location")
        }
    }

    private var speedBadge: some View {
        VStack {
            Text(speedText)
                .foregroundColor(.primary)
                .font(.caption)
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
                .font(.largeTitle)
                .bold()
                .padding()
                .foregroundColor(.black)

            Divider()
                .background(Color.secondary)

            List(directions.indices, id: \.self) { index in
                HStack {
                    Image(systemName: directionsIcon(directions[index]))
                    Text(directions[index])
                        .padding()
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
    }

    private func circularIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .modifier(CircularIconStyle())
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
