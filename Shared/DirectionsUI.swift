//
//  DirectionsUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Directions
struct DirectionsUI: View {
    @StateObject private var viewModel = DirectionsViewModel()
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

    private var stepsSection: some View {
        Section("Steps") {
            if viewModel.steps.isEmpty && !viewModel.isLoading {
                emptyStepsMessage
            } else {
                ForEach(viewModel.steps, id: \.self) { step in
                    HStack(alignment: .top) {
                        Image(systemName: DirectionIcon.systemName(for: step.instructions))
                            .frame(width: 24)
                        Text(step.instructions)
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

// MARK: - View Model
@MainActor
class DirectionsViewModel: ObservableObject {
    @Published var steps: [MKRoute.Step] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func calculateDirections(from: String, to: String) async {
        guard !from.isEmpty, !to.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        steps = []
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

            steps = route.steps.filter { !$0.instructions.isEmpty }
        } catch {
            errorMessage = error.localizedDescription
        }
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
