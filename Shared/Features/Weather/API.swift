//
//  API.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import Foundation
import CoreLocation

private var apiKey: String {
    Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String ?? ""
}

enum API {
    struct CurrentWeather {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        
        func url() throws -> URL {
            guard !apiKey.isEmpty else {
                throw URLError(.userAuthenticationRequired)
            }
            var components = URLComponents()
            components.scheme = "https"
            components.host = "api.openweathermap.org"
            components.path = "/data/2.5/weather"
            components.queryItems = [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lon", value: String(longitude)),
                URLQueryItem(name: "appid", value: apiKey),
                URLQueryItem(name: "units", value: "imperial")
            ]

            guard let url = components.url else {
                throw URLError(.badURL)
            }
            return url
        }
        
        struct Response: Decodable {
            var coord: CoordinatesResponse
            var weather: [WeatherResponse]
            var main: MainResponse
            var name: String
            var wind: WindResponse
            
            struct CoordinatesResponse: Decodable {
                var lon: Double
                var lat: Double
            }
            struct WeatherResponse: Decodable {
                var id: Double
                var main: String
                var description: String
                var icon: String
            }
            struct MainResponse: Decodable {
                var temp: Double
                var feels_like: Double
                var temp_min: Double
                var temp_max: Double
                var pressure: Double
                var humidity: Double
            }
            struct WindResponse: Decodable {
                var speed: Double
                var deg: Double
            }

            init(
                coord: CoordinatesResponse,
                weather: [WeatherResponse],
                main: MainResponse,
                name: String,
                wind: WindResponse
            ) {
                self.coord = coord
                self.weather = weather
                self.main = main
                self.name = name
                self.wind = wind
            }
        }
    }
}
