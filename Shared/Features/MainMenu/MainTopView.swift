//
//  MainTopView.swift
//  TheLightUI
//

import CoreMotion
import SwiftUI

// MARK: - Header
struct MainTopView: View {
    private enum Layout {
        @MainActor static var height: CGFloat {
            UIDevice.current.userInterfaceIdiom == .pad ? 200 : 145
        }
        static let cornerRadius: CGFloat = 20
        static let titleSize: CGFloat = 32
    }

    @AppStorage("color") private var color: Int?
    @AppStorage(SettingsUI.isCompanyNameKey) private var companyName: String = "Main Menu"
    @AppStorage(SettingsUI.backend) private var backEnd: String = "None"
    @State private var currentTemperatureText = "--°F"
    @State private var currentWeatherSystemImage = "cloud.sun.fill"
    @State private var currentStepsText = "--"
    @State private var isActive = true

    private let pedometer = CMPedometer()
    private let makeWeatherManager: () -> WeatherManaging
    private let makeWeatherLocationProvider: () -> WeatherLocationProviding

    init(
        makeWeatherManager: @escaping () -> WeatherManaging = { WeatherManager() },
        makeWeatherLocationProvider: @escaping () -> WeatherLocationProviding = { LocationWeatherManager() }
    ) {
        self.makeWeatherManager = makeWeatherManager
        self.makeWeatherLocationProvider = makeWeatherLocationProvider
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    private var titleRow: some View {
        HStack {
            Text(companyName)
                .font(.system(size: Layout.titleSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.top, 15)
                .padding(.leading, 15)
        }
    }

    private var backendRow: some View {
        statusRow(title: "Backend:", value: backEnd, systemImage: "circle.hexagongrid.fill")
            .symbolEffect(
                .variableColor
                .iterative
                .reversing
            )
    }

    private var stepsRow: some View {
        statusRow(title: "Steps:", value: currentStepsText, systemImage: "figure.walk", iconColor: .mint)
    }

    private var weatherRow: some View {
        statusRow(title: "Temp:", value: currentTemperatureText, systemImage: currentWeatherSystemImage)
            .padding(.bottom, 15)
    }

    var body: some View {
        VStack(alignment: .leading) {
            titleRow
            Divider()
            backendRow
            Spacer()
            stepsRow
            Spacer()
            weatherRow
        }
        .symbolRenderingMode(.multicolor)
        .foregroundStyle(.white)
        .background(themeColor)
        .clipShape(.rect(cornerRadius: Layout.cornerRadius))
        .frame(height: Layout.height, alignment: .leading)
        .padding()
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
            #endif
            isActive = true
            await loadCurrentTemperature()
            await loadTodaySteps()
        }
        .onDisappear {
            isActive = false
            pedometer.stopUpdates()
        }
    }

    @MainActor
    private func loadCurrentTemperature() async {
        guard isActive else { return }
        do {
            let coordinates = try await makeWeatherLocationProvider().requestLocation()
            let weather = try await makeWeatherManager().getCurrentWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            currentTemperatureText = "\(Int(weather.main.temp.rounded()))°F"
            currentWeatherSystemImage = systemImage(for: weather.weather.first)
        } catch {
            currentTemperatureText = "Unavailable"
            currentWeatherSystemImage = "cloud.sun.fill"
        }
    }

    @MainActor
    private func loadTodaySteps() async {
        guard isActive else { return }
        guard CMPedometer.isStepCountingAvailable() else {
            currentStepsText = "Unavailable"
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: .now)

        // Seed with today's accumulated steps, then stream live updates.
        applySteps(await todaySteps(from: startOfDay))

        for await steps in stepUpdates(from: startOfDay) {
            applySteps(steps)
        }
    }

    private func todaySteps(from startOfDay: Date) async -> Int? {
        await withCheckedContinuation { continuation in
            // CoreMotion invokes this handler on its own background queue. The
            // explicit `@Sendable` strips the `@MainActor` isolation this closure
            // would otherwise inherit from the enclosing context — without it the
            // Swift runtime traps with a dispatch queue assertion when CoreMotion
            // calls back off the main actor. It captures only the `Sendable`
            // continuation and hands off through a `nonisolated` converter.
            pedometer.queryPedometerData(from: startOfDay, to: .now) { @Sendable data, _ in
                continuation.resume(returning: data.map(Self.stepCount(from:)))
            }
        }
    }

    private func stepUpdates(from startOfDay: Date) -> AsyncStream<Int> {
        AsyncStream { continuation in
            pedometer.startUpdates(from: startOfDay) { @Sendable data, _ in
                guard let data else { return }
                continuation.yield(Self.stepCount(from: data))
            }
        }
    }

    /// Extracts a `Sendable` step count so pedometer readings can cross from
    /// CoreMotion's background queue to the main actor without carrying the
    /// non-`Sendable` `CMPedometerData` across the boundary.
    private nonisolated static func stepCount(from data: CMPedometerData) -> Int {
        data.numberOfSteps.intValue
    }

    @MainActor
    private func applySteps(_ steps: Int?) {
        guard isActive else { return }
        guard let steps else {
            currentStepsText = "Unavailable"
            return
        }

        currentStepsText = steps.formatted(.number)
    }

    private func systemImage(for weather: API.CurrentWeather.Response.WeatherResponse?) -> String {
        guard let weather else { return "cloud.sun.fill" }

        switch weather.main.lowercased() {
        case "clear":
            return weather.icon.hasSuffix("n") ? "moon.stars.fill" : "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "smoke", "haze", "dust", "fog", "sand", "ash", "squall", "tornado":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }

    private func statusRow(title: String, value: String, systemImage: String, iconColor: Color? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
            statusIcon(systemImage: systemImage, iconColor: iconColor)
        }
        .font(.callout.bold())
        .padding(.horizontal)
    }

    @ViewBuilder
    private func statusIcon(systemImage: String, iconColor: Color?) -> some View {
        if let iconColor {
            Image(systemName: systemImage)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(iconColor)
                .font(.callout)
                .imageScale(.large)
        } else {
            Image(systemName: systemImage)
                .font(.callout)
                .imageScale(.large)
        }
    }
}
