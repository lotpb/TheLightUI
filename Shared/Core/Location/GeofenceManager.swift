//
//  GeofenceManager.swift
//  TheLightUI (iOS)
//

import AVFoundation
import CoreLocation
import Observation
import UIKit

/// Manages circular geofences using CLMonitor.
/// - Fences persist across app launches (Core Location stores monitored conditions).
/// - Enter/exit events are delivered while the app is in use with when-in-use authorization.
@MainActor
@Observable
final class GeofenceManager {
    struct Geofence: Identifiable, Equatable {
        let id: String
        let center: CLLocationCoordinate2D
        let radius: CLLocationDistance

        static func == (lhs: Geofence, rhs: Geofence) -> Bool {
            lhs.id == rhs.id
                && lhs.center.latitude == rhs.center.latitude
                && lhs.center.longitude == rhs.center.longitude
                && lhs.radius == rhs.radius
        }
    }

    enum GeofenceEvent: Equatable {
        case entered(String)
        case exited(String)

        var message: String {
            switch self {
            case .entered(let name): return "Entered \(name)"
            case .exited(let name): return "Left \(name)"
            }
        }
    }

    static let shared = GeofenceManager()

    /// Core Location allows at most 20 monitored conditions per app.
    static let maxGeofences = 20
    static let defaultRadius: CLLocationDistance = 200
    private static let monitorName = "TheLightGeofenceMonitor"

    private(set) var geofences: [Geofence] = []

    private var monitor: CLMonitor?
    private var eventTask: Task<Void, Never>?
    private var alertPlayer: AVAudioPlayer?

    private init() {}

    var canAddGeofence: Bool {
        geofences.count < Self.maxGeofences
    }

    /// The default name the next fence would receive; useful as a placeholder in UI.
    var suggestedName: String {
        nextDefaultName()
    }

    /// Opens the shared monitor, restores persisted fences, and begins observing events.
    func start() async {
        guard monitor == nil else { return }
        await NotificationManager.shared.requestAuthorization()
        let monitor = await CLMonitor(Self.monitorName)
        self.monitor = monitor
        await restoreGeofences(from: monitor)
        observeEvents(of: monitor)
    }

    func addGeofence(
        named name: String? = nil,
        at center: CLLocationCoordinate2D,
        radius: CLLocationDistance = GeofenceManager.defaultRadius
    ) async {
        guard let monitor, canAddGeofence else { return }
        let identifier = uniqueIdentifier(from: name)
        let condition = CLMonitor.CircularGeographicCondition(center: center, radius: radius)
        await monitor.add(condition, identifier: identifier)
        geofences.append(Geofence(id: identifier, center: center, radius: radius))
    }

    func removeGeofence(_ geofence: Geofence) async {
        guard let monitor else { return }
        await monitor.remove(geofence.id)
        geofences.removeAll { $0.id == geofence.id }
    }

    func removeAllGeofences() async {
        guard let monitor else { return }
        for geofence in geofences {
            await monitor.remove(geofence.id)
        }
        geofences.removeAll()
    }

    private func restoreGeofences(from monitor: CLMonitor) async {
        var restored: [Geofence] = []
        for identifier in await monitor.identifiers {
            guard let condition = await monitor.record(for: identifier)?.condition as? CLMonitor.CircularGeographicCondition else { continue }
            restored.append(Geofence(id: identifier, center: condition.center, radius: condition.radius))
        }
        geofences = restored
    }

    private func observeEvents(of monitor: CLMonitor) {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            do {
                for try await event in await monitor.events {
                    self?.handle(event)
                }
            } catch {
                print("Geofence monitoring stopped: \(error.localizedDescription)")
            }
        }
    }

    /// User-facing switch in Settings > Map; read live so toggling applies without a restart.
    private var alertsEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsUI.isGeofenceAlertsKey) as? Bool ?? true
    }

    private func handle(_ event: CLMonitor.Event) {
        guard alertsEnabled else { return }
        let geofenceEvent: GeofenceEvent
        switch event.state {
        case .satisfied:
            geofenceEvent = .entered(event.identifier)
        case .unsatisfied:
            geofenceEvent = .exited(event.identifier)
        default:
            return
        }
        playAlertSound()
        NotificationManager.shared.postNotification(
            title: "Geofence",
            body: geofenceEvent.message,
            categoryIdentifier: "geofence"
        )
    }

    /// Plays the Tornado alert from the asset catalog when a fence fires.
    private func playAlertSound() {
        guard let asset = NSDataAsset(name: "Tornado") else {
            print("Geofence alert sound asset not found")
            return
        }
        do {
            let player = try AVAudioPlayer(data: asset.data, fileTypeHint: AVFileType.caf.rawValue)
            alertPlayer = player
            player.play()
        } catch {
            print("Failed to play geofence alert sound: \(error.localizedDescription)")
        }
    }

    /// Fence names double as CLMonitor identifiers, so they must be unique.
    private func uniqueIdentifier(from name: String?) -> String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nextDefaultName() }

        let existing = Set(geofences.map(\.id))
        guard existing.contains(trimmed) else { return trimmed }

        var index = 2
        while existing.contains("\(trimmed) \(index)") {
            index += 1
        }
        return "\(trimmed) \(index)"
    }

    private func nextDefaultName() -> String {
        let existing = Set(geofences.map(\.id))
        var index = geofences.count + 1
        while existing.contains("Geofence \(index)") {
            index += 1
        }
        return "Geofence \(index)"
    }
}
