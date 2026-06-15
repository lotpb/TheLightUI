//
//  WeatherUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI
import CoreLocation

@available(iOS 15.0, *)
struct WeatherUI: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: ViewModel

    @MainActor
    init(
        apiManager: WeatherManaging = WeatherManager(),
        locationManager: WeatherLocationProviding = LocationWeatherManager()
    ) {
        _viewModel = StateObject(wrappedValue: ViewModel(apiManager: apiManager, locationManager: locationManager))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.viewState {
                case .welcome:
                    WelcomeView(requestLocation: { viewModel.requestLocation() })
                case .coordinatesFetched(let coordinates):
                    VStack {
                        Text("Your coordinates are: \(coordinates.latitude), \(coordinates.longitude)")
                        ProgressView()
                    }
                    .task {
                        await viewModel.fetchWeather(from: coordinates)
                    }
                case .weatherFetched(let weather):
                    WeatherView(weather: weather)
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                case .loading:
                    LoadingView()
                }
                Spacer()
            }
            
            .background(Color.background)
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            
            
        }

    }
}

@available(iOS 15.0, *)
extension WeatherUI {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: Private variables
        private let apiManager: WeatherManaging
        private let locationManager: WeatherLocationProviding
        // MARK: Public variables
        @Published public var viewState: ViewState = .welcome
        // MARK: Nested objects
        enum ViewState {
            case welcome
            case loading
            case coordinatesFetched(CLLocationCoordinate2D)
            case weatherFetched(API.CurrentWeather.Response)
            case failed(Swift.Error)
        }
        
        // MARK: Lifecycle
        init(apiManager: WeatherManaging, locationManager: WeatherLocationProviding) {
            self.apiManager = apiManager
            self.locationManager = locationManager
        }
        
        // MARK: Public interface
        public func requestLocation() {
            viewState = .loading
            Task {
                do {
                    let coordinates = try await locationManager.requestLocation()
                    viewState = .coordinatesFetched(coordinates)
                } catch {
                    viewState = .failed(error)
                }
            }
        }

        public func fetchWeather(from coordinates: CLLocationCoordinate2D) async {
            do {
                let weather = try await apiManager.getCurrentWeather(latitude: coordinates.latitude, longitude: coordinates.longitude)
                viewState = .weatherFetched(weather)
            } catch {
                viewState = .failed(error)
            }
        }
    }
}

@available(iOS 15.0, *)
struct WeatherUI_Previews: PreviewProvider {
    static var previews: some View {
        WeatherUI(
            apiManager: PreviewWeatherManager(),
            locationManager: PreviewWeatherLocationProvider()
        )
    }
}
