//
//  GeofenceEditorSheet.swift
//  TheLightUI
//

import CoreLocation
import SwiftUI

/// The coordinate captured when the user chooses "Add Geofence Here",
/// wrapped as an Identifiable so the sheet is built with the correct value.
struct GeofenceDraft: Identifiable {
    let id = UUID()
    let center: CLLocationCoordinate2D
}

/// A form for naming a new geofence and choosing its radius before adding it.
struct GeofenceEditorSheet: View {
    let center: CLLocationCoordinate2D

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var radius: Double = GeofenceManager.defaultRadius

    private let geofenceManager = GeofenceManager.shared
    private static let radiusRange: ClosedRange<Double> = 50...1000

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField(geofenceManager.suggestedName, text: $name)
                }

                Section("Radius") {
                    VStack(alignment: .leading, spacing: 4) {
                        Slider(value: $radius, in: Self.radiusRange, step: 50) {
                            Text("Radius")
                        }
                        Text(formattedRadius)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .navigationTitle("New Geofence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addGeofence() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var formattedRadius: String {
        let style = Measurement<UnitLength>.FormatStyle(width: .abbreviated, usage: .road)
        return Measurement(value: radius, unit: UnitLength.meters).formatted(style)
    }

    private func addGeofence() {
        let name = name
        let center = center
        let radius = radius
        Task {
            await GeofenceManager.shared.addGeofence(named: name, at: center, radius: radius)
        }
        dismiss()
    }
}

#Preview("Geofence Editor") {
    GeofenceEditorSheet(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060))
}
