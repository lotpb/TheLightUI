//
//  DirectionsUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Observation

// MARK: - Directions
struct DirectionsUI: View {
    @State private var viewModel = DirectionsViewModel()
    @State private var from = "5121 Lakefront Blvd Apt D, Delray Beach, FL, 33484"
    @State private var to = "Santa Monica, CA"

    var body: some View {
        NavigationStack {
            directionsForm
                .navigationTitle("Directions")
        }
    }

    // MARK: - Content

    private var directionsForm: some View {
        Form {
            routeSection
            errorSection
            routeDistanceSection
            stepsSection
        }
    }

    private var routeSection: some View {
        Section("Route") {
            TextField("Choose starting location", text: $from)
                .textInputAutocapitalization(.words)
            TextField("Choose destination", text: $to)
                .textInputAutocapitalization(.words)
            searchButton
        }
    }

    private var searchButton: some View {
        let start = from.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = to.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEnabled = !viewModel.isLoading && !start.isEmpty && !end.isEmpty
        return Button(action: { calculateDirections(start: start, end: end) }) {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Label("Search", systemImage: "magnifyingglass").frame(maxWidth: .infinity)
            }
        }
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var routeDistanceSection: some View {
        if viewModel.routeDistance != nil {
            Section("Distance") {
                HStack(spacing: 12) {
                    Image(systemName: "map")
                        .frame(width: 24)

                    Text(viewModel.routeDistanceText)

                    Spacer(minLength: 12)

                    Text(viewModel.routeTravelTimeText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var stepsSection: some View {
        Section("Steps") {
            if viewModel.steps.isEmpty && !viewModel.isLoading {
                emptyStepsMessage
            } else {
                ForEach(viewModel.steps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: DirectionIcon.systemName(for: step.instructions))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.instructions)
                            Text(step.distanceText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer(minLength: 12)

                        Text(step.travelTimeText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }

    private var emptyStepsMessage: some View {
        Text("No directions loaded")
            .foregroundColor(.secondary)
    }

    // MARK: - Actions

    private func calculateDirections(start: String, end: String) {
        Task { await viewModel.calculateDirections(from: start, to: end) }
    }
}

private enum DirectionIcon {
    static func systemName(for instruction: String) -> String {
        let lowercasedInstruction = instruction.lowercased()

        if lowercasedInstruction.contains("right") {
            return "arrow.turn.up.right"
        } else if lowercasedInstruction.contains("left") {
            return "arrow.turn.up.left"
        } else if lowercasedInstruction.contains("destination") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up"
        }
    }
}

private struct DirectionStepDisplay: Identifiable {
    let id = UUID()
    let instructions: String
    let distanceText: String
    let travelTimeText: String
}

private extension Double {
    var formattedDistance: String {
        let measurement = Measurement(value: self, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: measurement)
    }
}

// MARK: - View Model
@MainActor
@Observable
private class DirectionsViewModel {
    var steps: [DirectionStepDisplay] = []
    var routeDistance: CLLocationDistance?
    var routeTravelTime: TimeInterval?
    var isLoading = false
    var errorMessage: String?

    var routeDistanceText: String {
        guard let routeDistance else { return "" }
        return Self.formatDistance(routeDistance)
    }

    var routeTravelTimeText: String {
        guard let routeTravelTime else { return "" }
        return Self.formatTravelTime(routeTravelTime)
    }

    func calculateDirections(from: String, to: String) async {
        guard !from.isEmpty, !to.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        steps = []
        routeDistance = nil
        routeTravelTime = nil
        defer { isLoading = false }

        do {
            guard let startPlacemark = try await placemark(for: from),
                  let destinationPlacemark = try await placemark(for: to) else {
                errorMessage = "Unable to find one of those locations."
                return
            }

            let response = try await MKDirections(request: request(from: startPlacemark, to: destinationPlacemark)).calculate()
            guard let route = response.routes.first else {
                errorMessage = "No route found."
                return
            }

            routeDistance = route.distance
            routeTravelTime = route.expectedTravelTime
            steps = route.steps.compactMap { step in
                guard !step.instructions.isEmpty else { return nil }

                let distanceText = Self.formatDistance(step.distance)
                let travelTimeText = Self.formatTravelTime(Self.estimatedTravelTime(for: step, in: route))
                return DirectionStepDisplay(
                    instructions: step.instructions,
                    distanceText: distanceText,
                    travelTimeText: travelTimeText
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func formatDistance(_ distance: CLLocationDistance) -> String {
        distance.formattedDistance
    }

    private static func formatTravelTime(_ travelTime: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = travelTime >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: max(travelTime, 60)) ?? "1 min"
    }

    private static func estimatedTravelTime(for step: MKRoute.Step, in route: MKRoute) -> TimeInterval {
        guard route.distance > 0 else { return 0 }
        return route.expectedTravelTime * (step.distance / route.distance)
    }

    private func placemark(for address: String) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        return try await geocoder.geocodeAddressString(address).first
    }

    private func request(from startPlacemark: CLPlacemark, to destinationPlacemark: CLPlacemark) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.transportType = .automobile
        request.source = MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
        request.destination = MKMapItem(placemark: MKPlacemark(placemark: destinationPlacemark))
        return request
    }
}

// MARK: - Preview
#Preview("Directions - Dark") {
    DirectionsUI()
        .preferredColorScheme(.dark)
}
