//
//  API.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import Foundation
import CoreLocation

private let apiKey = "2fc60777eed08d159cb110705242160d"

enum API {
    struct CurrentWeather {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        
        func url() -> URL {
            guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric") else { fatalError("Missing URL") }
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
        }
    }
}
