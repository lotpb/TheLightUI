//
//  WeatherView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI

struct WeatherView: View {
    var weather: API.CurrentWeather.Response

    /// The primary reported condition, with a safe fallback so the view never
    /// crashes on an unexpectedly empty `weather` array.
    private var condition: API.CurrentWeather.Response.WeatherResponse {
        weather.weather.first ?? .init(id: 0, main: "Clear", description: "clear sky", icon: "01d")
    }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(weather.name)
                        .bold().font(.title)
                    Text("Today, \(Date().formatted(.dateTime.month().day().hour().minute()))")
                        .fontWeight(.light)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: condition.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 50))
                            Text(condition.description.capitalized)
                                .font(.headline)
                        }
                        .frame(width: 150, alignment: .leading)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(weather.main.temp.string() + "°")
                                .font(.system(size: 80, weight: .bold))
                                .contentTransition(.numericText())
                            Text("Feels like \(weather.main.feels_like.string())°")
                                .font(.callout)
                                .opacity(0.85)
                        }
                    }

                    Spacer()
                        .frame(height: 60)

                    AsyncImage(url: URL(string: "https://cdn.pixabay.com/photo/2020/01/24/21/33/city-4791269_960_720.png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 350)
                    } placeholder: {
                        ProgressView()
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Weather now")
                        .bold().padding(.bottom)

                    HStack {
                        WeatherRow(type: .minTemp(value: weather.main.temp_min))
                        Spacer()
                        WeatherRow(type: .maxTemp(value: weather.main.temp_max))
                    }
                    HStack {
                        WeatherRow(type: .wind(value: weather.wind.speed))
                        Spacer()
                        WeatherRow(type: .humidity(value: weather.main.humidity))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, 20)
                .foregroundStyle(Color.background)
                .background(.white)
                .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 20))
            }
        }
        .foregroundStyle(.white)
        .ignoresSafeArea(edges: .bottom)
        .background(
            LinearGradient(colors: condition.skyColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - Condition presentation

private extension API.CurrentWeather.Response.WeatherResponse {
    /// OpenWeather appends "n" to the icon code for night-time conditions.
    var isNight: Bool { icon.hasSuffix("n") }

    /// An SF Symbol that reflects the reported condition and time of day.
    var symbolName: String {
        switch main.lowercased() {
        case "clear":
            isNight ? "moon.stars.fill" : "sun.max.fill"
        case "clouds":
            isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case "rain", "drizzle":
            "cloud.rain.fill"
        case "thunderstorm":
            "cloud.bolt.rain.fill"
        case "snow":
            "snowflake"
        case "mist", "fog", "haze", "smoke":
            "cloud.fog.fill"
        default:
            isNight ? "moon.fill" : "sun.max.fill"
        }
    }

    /// A top-to-bottom sky gradient tuned to the condition and time of day.
    var skyColors: [Color] {
        if isNight {
            return [Color(red: 0.06, green: 0.09, blue: 0.22), Color(red: 0.12, green: 0.15, blue: 0.32)]
        }
        switch main.lowercased() {
        case "clouds":
            return [Color(red: 0.36, green: 0.45, blue: 0.55), Color(red: 0.55, green: 0.63, blue: 0.72)]
        case "rain", "drizzle", "thunderstorm":
            return [Color(red: 0.26, green: 0.32, blue: 0.40), Color(red: 0.40, green: 0.47, blue: 0.55)]
        case "snow":
            return [Color(red: 0.45, green: 0.55, blue: 0.65), Color(red: 0.70, green: 0.78, blue: 0.85)]
        default:
            return [Color(red: 0.20, green: 0.50, blue: 0.85), Color(red: 0.46, green: 0.73, blue: 0.96)]
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView(weather: try! Bundle.main.url(forResource: "weatherData", withExtension: "json")!.load())
    }
}
