//
//  DirectionsUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI
import CoreLocation
import MapKit

struct DirectionsUI: View {
    @StateObject private var viewModel = DirectionsViewModel()
    
    @State private var from = "5121 Lakefront Blvd Apt D, Delray Beach, FL, 33484"
    @State private var to = "Santa Monica, CA"
    
    private var trimmedFrom: String {
        from.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedTo: String {
        to.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSearch: Bool {
        !viewModel.isLoading && !trimmedFrom.isEmpty && !trimmedTo.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                routeSection
                errorSection
                stepsSection
            }
            .navigationTitle("Directions")
        }
    }
    
    private var routeSection: some View {
        Section("Route") {
            TextField("Choose starting location", text: $from)
                .textInputAutocapitalization(.words)
            TextField("Choose destination", text: $to)
                .textInputAutocapitalization(.words)
            
            Button(action: calculateDirections) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Search", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!canSearch)
        }
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
                Text("No directions loaded")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.steps, id: \.self) { step in
                    directionStepRow(step)
                }
            }
        }
    }
    
    private func directionStepRow(_ step: MKRoute.Step) -> some View {
        HStack(alignment: .top) {
            Image(systemName: Self.directionsIcon(for: step.instructions))
                .frame(width: 24)
            Text(step.instructions)
        }
    }
    
    private func calculateDirections() {
        Task {
            await viewModel.calculateDirections(from: trimmedFrom, to: trimmedTo)
        }
    }
    
    private static func directionsIcon(for instruction: String) -> String {
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
            
            let request = MKDirections.Request()
            request.transportType = .automobile
            request.source = MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
            request.destination = MKMapItem(placemark: MKPlacemark(placemark: destinationPlacemark))
            
            let response = try await MKDirections(request: request).calculate()
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
}

#Preview("Directions - Dark") {
    DirectionsUI()
        .preferredColorScheme(.dark)
}
