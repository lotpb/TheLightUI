//
//  WeatherUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI
import CoreLocation
import Combine

@available(iOS 15.0, *)
struct WeatherUI: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.viewState {
                case .welcome:
                    WelcomeView(requestLocation: { viewModel.requestLocation() })
                case .coordinatesFetched(let coordinates):
                    VStack {
                        Text("Your coordinates are: \(coordinates.longitude), \(coordinates.latitude)")
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
    class ViewModel: ObservableObject {
        // MARK: Private variables
        private let apiManager: WeatherManager
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
        init(apiManager: WeatherManager = WeatherManager()) {
            self.apiManager = apiManager
        }
        
        // MARK: Public interface
        public func requestLocation() {
            viewState = .loading
            LocationWeatherManager().requestLocation { result in
                switch result {
                case .success(let coordinates):
                    self.viewState = .coordinatesFetched(coordinates)
                case .failure(let error):
                    self.viewState = .failed(error)
                }
            }
        }
        public func fetchWeather(from coordinates: CLLocationCoordinate2D) async {
            do {
                let weather = try await apiManager.getCurrentWeather(latitude: coordinates.latitude, longitude: coordinates.longitude)
                DispatchQueue.onMain {
                    self.viewState = .weatherFetched(weather)
                }
            } catch {
                DispatchQueue.onMain {
                    self.viewState = .failed(error)
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct WeatherUI_Previews: PreviewProvider {
    static var previews: some View {
        WeatherUI()
    }
}
