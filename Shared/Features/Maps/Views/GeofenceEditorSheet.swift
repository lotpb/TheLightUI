//
//  GeofenceEditorSheet.swift
//  TheLightUI
//

import CoreLocation
import MapKit
import SwiftUI

/// The coordinate captured when the user chooses "Add Geofence Here",
/// wrapped as an Identifiable so the sheet is built with the correct value.
struct GeofenceDraft: Identifiable {
    let id = UUID()
    let center: CLLocationCoordinate2D
}

/// A form for naming a new geofence, positioning its center pin, and choosing
/// its radius before adding it. The pin can be dragged on the map to fine-tune
/// where the fence is placed.
struct GeofenceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var center: CLLocationCoordinate2D
    @State private var name = ""
    @State private var radius: Double = GeofenceManager.defaultRadius

    private let geofenceManager = GeofenceManager.shared
    private static let radiusRange: ClosedRange<Double> = 50...1000

    init(center: CLLocationCoordinate2D) {
        self._center = State(initialValue: center)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    mapSection
                        .frame(height: 220)
                        .listRowInsets(EdgeInsets())
                } footer: {
                    Text("Drag the pin to adjust the geofence location.")
                }

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
        .presentationDetents([.medium, .large])
    }

    /// A map preview of the fence. The pin is draggable: the drag location is
    /// converted back to a coordinate through the MapProxy.
    private var mapSection: some View {
        MapReader { proxy in
            Map(initialPosition: .region(initialRegion)) {
                MapCircle(center: center, radius: radius)
                    .foregroundStyle(.blue.opacity(0.15))
                    .stroke(.blue, lineWidth: 2)

                Annotation("", coordinate: center) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 34))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 2)
                        .gesture(
                            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                                .onChanged { value in
                                    if let coordinate = proxy.convert(value.location, from: .global) {
                                        center = coordinate
                                    }
                                }
                        )
                }
            }
        }
    }

    /// A region wide enough to show the largest selectable radius around the pin.
    private var initialRegion: MKCoordinateRegion {
        let span = Self.radiusRange.upperBound * 2.5
        return MKCoordinateRegion(center: center, latitudinalMeters: span, longitudinalMeters: span)
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
