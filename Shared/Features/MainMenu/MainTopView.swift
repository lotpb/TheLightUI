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
            UIDevice.current.userInterfaceIdiom == .pad ? 260 : 150
        }
        static let cornerRadius: CGFloat = 18

        @MainActor static var logoHeight: CGFloat {
            UIDevice.current.userInterfaceIdiom == .pad ? 180 : 80
        }
        @MainActor static var logoWidth: CGFloat {
            UIDevice.current.userInterfaceIdiom == .pad ? 360 : 160
        }
    }

    @AppStorage(SettingsUI.color) private var color: Int?
    @AppStorage(SettingsUI.isCompanyNameKey) private var companyName: String = "Main Menu"
    @AppStorage(SettingsUI.backend) private var backEnd: String = "SwiftData"
    @State private var currentTemperatureText = "--°F"
    @State private var currentWeatherSystemImage = "cloud.sun.fill"
    @State private var currentStepsText = "--"
    @State private var isActive = true

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

    // MARK: - Subviews

    private var logoRow: some View {
        HStack(spacing: 10) {
            Image("TheLight background")
                .resizable()
                .scaledToFit()
                .frame(height: Layout.logoHeight)
                .frame(width: Layout.logoWidth)
                .padding(.leading, 16)
                .padding(.top, 4)
            //Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 6) {
            backendChip
            Spacer()
            stepsChip
            weatherChip
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private var backendChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.subheadline)
                .symbolEffect(.variableColor.iterative.reversing)
            Text(backEnd)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .chipStyle()
    }

    private var stepsChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "figure.walk")
                .foregroundStyle(.mint)
                .font(.subheadline)
            Text(currentStepsText)
                .font(.subheadline.weight(.semibold))
        }
        .chipStyle()
    }

    private var weatherChip: some View {
        HStack(spacing: 5) {
            Image(systemName: currentWeatherSystemImage)
                .font(.subheadline)
            Text(currentTemperatureText)
                .font(.subheadline.weight(.semibold))
        }
        .chipStyle()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoRow
            statsRow
            Spacer(minLength: 8)
        }
        .symbolRenderingMode(.multicolor)
        .foregroundStyle(.white)
        .background(headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: themeColor.opacity(0.35), radius: 12, x: 0, y: 6)
        .frame(height: Layout.height, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 4)
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                currentStepsText = 3240.formatted(.number)
                return
            }
            #endif
            isActive = true
            await loadCurrentTemperature()
            await loadTodaySteps()
        }
        .onDisappear {
            isActive = false
        }
    }

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [themeColor, themeColor.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Data Loading

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
        let pedometer = CMPedometer()
        defer { pedometer.stopUpdates() }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        applySteps(await todaySteps(from: startOfDay, pedometer: pedometer))
        for await steps in stepUpdates(from: startOfDay, pedometer: pedometer) {
            applySteps(steps)
        }
    }

    private func todaySteps(from startOfDay: Date, pedometer: CMPedometer) async -> Int? {
        await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: startOfDay, to: .now) { @Sendable data, _ in
                continuation.resume(returning: data.map(Self.stepCount(from:)))
            }
        }
    }

    private func stepUpdates(from startOfDay: Date, pedometer: CMPedometer) -> AsyncStream<Int> {
        AsyncStream { continuation in
            pedometer.startUpdates(from: startOfDay) { @Sendable data, _ in
                guard let data else { return }
                continuation.yield(Self.stepCount(from: data))
            }
        }
    }

    private nonisolated static func stepCount(from data: CMPedometerData) -> Int {
        data.numberOfSteps.intValue
    }

    @MainActor
    private func applySteps(_ steps: Int?) {
        guard isActive else { return }
        guard let steps else {
            currentStepsText = stepsUnavailableText
            return
        }
        currentStepsText = steps.formatted(.number)
    }

    private var stepsUnavailableText: String {
        switch CMPedometer.authorizationStatus() {
        case .denied, .restricted: "Off in Settings"
        default: "Unavailable"
        }
    }

    private func systemImage(for weather: API.CurrentWeather.Response.WeatherResponse?) -> String {
        guard let weather else { return "cloud.sun.fill" }
        switch weather.main.lowercased() {
        case "clear":        return weather.icon.hasSuffix("n") ? "moon.stars.fill" : "sun.max.fill"
        case "clouds":       return "cloud.fill"
        case "rain", "drizzle": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow":         return "cloud.snow.fill"
        default:             return "cloud.sun.fill"
        }
    }
}

// MARK: - Chip Style

private extension View {
    func chipStyle() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
    }
}
