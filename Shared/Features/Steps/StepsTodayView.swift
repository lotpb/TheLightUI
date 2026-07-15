//
//  StepsTodayView.swift
//  TheLightUI
//

import CoreMotion
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StepsTodayView: View {
    @AppStorage("color") private var color: Int?
    @State private var viewModel = StepsTodayViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.tabBarOverlap) private var tabBarOverlap

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    var body: some View {
        List {
            summarySection
            detailsSection
            yesterdaySection
        }
        .listStyle(.insetGrouped)
        // The custom tab bar's safe-area inset is applied outside this
        // screen's NavigationStack, which doesn't forward it to the List's
        // scroll insets — re-apply it so the last row rests above the bar.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: tabBarOverlap)
                .allowsHitTesting(false)
        }
        .navigationTitle("Steps Today")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeColor)
        .task {
            viewModel.startTrackingToday()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.startTrackingToday()
            } else {
                viewModel.stopTracking()
            }
        }
    }

    private var summarySection: some View {
        Section {
            VStack(spacing: 20) {
                progressRing

                HStack(spacing: 12) {
                    StepsMetricView(
                        title: "Goal",
                        value: viewModel.dailyGoal.formatted(.number),
                        systemImage: "target",
                        accentColor: themeColor
                    )
                    StepsMetricView(
                        title: viewModel.goalReached ? "Reached" : "Remaining",
                        value: viewModel.goalReached ? "Done" : viewModel.stepsRemaining.formatted(.number),
                        systemImage: viewModel.goalReached ? "checkmark.seal.fill" : "flag.checkered",
                        accentColor: themeColor
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(themeColor.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: viewModel.goalProgress)
                .stroke(themeColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: viewModel.goalProgress)

            VStack(spacing: 4) {
                Image(systemName: viewModel.goalReached ? "checkmark" : "figure.walk")
                    .font(.title2)
                    .foregroundStyle(themeColor)
                    .contentTransition(.symbolEffect(.replace))

                Text(viewModel.steps, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(viewModel.goalReached ? "Goal reached!" : "\(viewModel.goalPercentText) of goal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(34)
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steps today")
        .accessibilityValue("\(viewModel.steps) steps, \(viewModel.goalPercentText) of daily goal")
    }

    private var detailsSection: some View {
        Section("Today") {
            LabeledContent("Since") {
                Text(viewModel.startOfDay, style: .time)
            }

            if let distanceText = viewModel.distanceText {
                LabeledContent("Distance") {
                    Text(distanceText)
                }
            }

            LabeledContent("Status") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.statusColor)
                        .frame(width: 8, height: 8)
                    Text(viewModel.statusText)
                        .foregroundStyle(viewModel.statusColor)
                }
            }

            Button {
                viewModel.startTrackingToday()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            if viewModel.needsSettings {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
            }
        }
    }

    private var yesterdaySection: some View {
        Section("Yesterday") {
            LabeledContent("Steps") {
                if let yesterdaySteps = viewModel.yesterdaySteps {
                    Text(yesterdaySteps, format: .number)
                        .monospacedDigit()
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #endif
    }
}

@MainActor
@Observable
private final class StepsTodayViewModel {
    private(set) var steps = 0
    private(set) var yesterdaySteps: Int?
    private(set) var distanceMeters: Double?
    private(set) var statusText = "Loading"
    private(set) var statusColor: Color = .secondary

    let dailyGoal = 10_000

    @ObservationIgnored private let pedometer = CMPedometer()
    @ObservationIgnored private var trackingTask: Task<Void, Never>?

    /// A `Sendable` snapshot of pedometer readings, so values can cross from
    /// CoreMotion's background queue to the main actor without passing the
    /// non-`Sendable` `CMPedometerData` across actor boundaries.
    private struct StepsSample: Sendable {
        let steps: Int
        let distanceMeters: Double?
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: .now)
    }

    var goalProgress: Double {
        min(Double(steps) / Double(dailyGoal), 1)
    }

    var goalPercentText: String {
        goalProgress.formatted(.percent.precision(.fractionLength(0)))
    }

    var stepsRemaining: Int {
        max(dailyGoal - steps, 0)
    }

    var goalReached: Bool {
        steps >= dailyGoal
    }

    /// Whether motion access has been refused, so the UI can offer a jump to
    /// Settings rather than leaving the user stuck.
    var needsSettings: Bool {
        switch CMPedometer.authorizationStatus() {
        case .denied, .restricted:
            true
        default:
            false
        }
    }

    var distanceText: String? {
        guard let distanceMeters else { return nil }
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return measurement.formatted(.measurement(width: .abbreviated, usage: .road))
    }

    func startTrackingToday() {
        guard CMPedometer.isStepCountingAvailable() else {
            steps = 0
            distanceMeters = nil
            statusText = "Not Available"
            statusColor = .secondary
            return
        }

        updateStatus()

        guard trackingTask == nil else { return }
        trackingTask = Task { [weak self] in
            await self?.track()
        }
    }

    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }

    private func track() async {
        // Yesterday's total is independent of live tracking, so a failure
        // here just leaves the cell showing a placeholder.
        yesterdaySteps = try? await yesterdaySample()?.steps

        // Seed with today's accumulated data, then stream live updates.
        do {
            if let sample = try await todaySample() {
                apply(sample)
            }
        } catch {
            steps = 0
            distanceMeters = nil
            statusText = error.localizedDescription
            statusColor = .red
            return
        }

        for await sample in pedometerUpdates() {
            apply(sample)
        }
    }

    private func todaySample() async throws -> StepsSample? {
        try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: startOfDay, to: .now) { @Sendable data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data.map(Self.sample(from:)))
                }
            }
        }
    }

    private func yesterdaySample() async throws -> StepsSample? {
        let startOfToday = startOfDay
        guard let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: startOfToday) else {
            return nil
        }
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: startOfYesterday, to: startOfToday) { @Sendable data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data.map(Self.sample(from:)))
                }
            }
        }
    }

    private func pedometerUpdates() -> AsyncStream<StepsSample> {
        AsyncStream { continuation in
            pedometer.startUpdates(from: startOfDay) { @Sendable data, _ in
                guard let data else { return }
                continuation.yield(Self.sample(from: data))
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.pedometer.stopUpdates()
                }
            }
        }
    }

    private nonisolated static func sample(from data: CMPedometerData) -> StepsSample {
        StepsSample(steps: data.numberOfSteps.intValue, distanceMeters: data.distance?.doubleValue)
    }

    private func apply(_ sample: StepsSample) {
        steps = sample.steps
        distanceMeters = sample.distanceMeters
        updateStatus()
    }

    private func updateStatus() {
        let authorizationStatus = CMPedometer.authorizationStatus()
        statusText = status(for: authorizationStatus)
        statusColor = statusColor(for: authorizationStatus)
    }

    private func status(for authorizationStatus: CMAuthorizationStatus) -> String {
        switch authorizationStatus {
        case .notDetermined:
            "Permission Needed"
        case .restricted:
            "Restricted"
        case .denied:
            "Denied"
        case .authorized:
            "Tracking"
        @unknown default:
            "Unknown"
        }
    }

    private func statusColor(for authorizationStatus: CMAuthorizationStatus) -> Color {
        switch authorizationStatus {
        case .authorized:
            .green
        case .denied, .restricted:
            .red
        case .notDetermined:
            .secondary
        @unknown default:
            .secondary
        }
    }
}

private struct StepsMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview("Steps Today") {
    NavigationStack {
        StepsTodayView()
    }
}
