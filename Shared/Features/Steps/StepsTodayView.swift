//
//  StepsTodayView.swift
//  TheLightUI
//

import CoreMotion
import SwiftUI

struct StepsTodayView: View {
    @AppStorage("color") private var color: Int?
    @StateObject private var viewModel = StepsTodayViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    var body: some View {
        List {
            summarySection
            detailsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Steps Today")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeColor)
        .accentColor(themeColor)
        .task {
            viewModel.startTrackingToday()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.startTrackingToday()
            } else {
                viewModel.stopTracking()
            }
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.steps, format: .number)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer()

                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(themeColor)
                }

                ProgressView(value: viewModel.goalProgress)
                    .tint(themeColor)
                    .accessibilityLabel("Daily step goal progress")

                HStack(spacing: 12) {
                    StepsMetricView(
                        title: "Goal",
                        value: viewModel.dailyGoal.formatted(.number),
                        systemImage: "target",
                        accentColor: themeColor
                    )
                    StepsMetricView(
                        title: "Progress",
                        value: viewModel.goalPercentText,
                        systemImage: "chart.line.uptrend.xyaxis",
                        accentColor: themeColor
                    )
                }
            }
            .padding(.vertical, 6)
        }
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
                Text(viewModel.statusText)
                    .foregroundStyle(viewModel.statusColor)
            }

            Button {
                viewModel.startTrackingToday()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
}

@MainActor
private final class StepsTodayViewModel: ObservableObject {
    @Published private(set) var steps = 0
    @Published private(set) var distanceMeters: Double?
    @Published private(set) var statusText = "Loading"
    @Published private(set) var statusColor: Color = .secondary

    let dailyGoal = 10_000

    private let pedometer = CMPedometer()
    private var isTracking = false

    var startOfDay: Date {
        Calendar.current.startOfDay(for: .now)
    }

    var goalProgress: Double {
        min(Double(steps) / Double(dailyGoal), 1)
    }

    var goalPercentText: String {
        goalProgress.formatted(.percent.precision(.fractionLength(0)))
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

        statusText = status(for: CMPedometer.authorizationStatus())
        statusColor = statusColor(for: CMPedometer.authorizationStatus())

        queryToday()

        guard !isTracking else { return }
        isTracking = true
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            Task { @MainActor in
                self?.handle(data: data, error: error)
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
        isTracking = false
    }

    private func queryToday() {
        pedometer.queryPedometerData(from: startOfDay, to: .now) { [weak self] data, error in
            Task { @MainActor in
                self?.handle(data: data, error: error)
            }
        }
    }

    private func handle(data: CMPedometerData?, error: Error?) {
        if let error {
            steps = 0
            distanceMeters = nil
            statusText = error.localizedDescription
            statusColor = .red
            return
        }

        guard let data else {
            statusText = "No Data"
            statusColor = .secondary
            return
        }

        steps = data.numberOfSteps.intValue
        distanceMeters = data.distance?.doubleValue
        statusText = status(for: CMPedometer.authorizationStatus())
        statusColor = statusColor(for: CMPedometer.authorizationStatus())
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
