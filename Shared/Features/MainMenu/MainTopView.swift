//
//  MainTopView.swift
//  TheLightUI
//

import CoreMotion
import SwiftUI

// MARK: - Header
struct MainTopView: View {
    private enum Layout {
        static let height: CGFloat = 145
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
            loadTodaySteps()
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
    private func loadTodaySteps() {
        guard isActive else { return }
        guard CMPedometer.isStepCountingAvailable() else {
            currentStepsText = "Unavailable"
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: .now)
        pedometer.queryPedometerData(from: startOfDay, to: .now) { data, error in
            Task { @MainActor in
                updateSteps(data: data, error: error)
            }
        }

        pedometer.startUpdates(from: startOfDay) { data, error in
            Task { @MainActor in
                updateSteps(data: data, error: error)
            }
        }
    }

    @MainActor
    private func updateSteps(data: CMPedometerData?, error: Error?) {
        guard isActive else { return }
        guard error == nil, let data else {
            currentStepsText = "Unavailable"
            return
        }

        currentStepsText = data.numberOfSteps.intValue.formatted(.number)
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
