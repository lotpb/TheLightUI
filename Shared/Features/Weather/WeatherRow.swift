//
//  WeatherRow.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI

struct WeatherRow: View {
    var type: RowType
    
    var body: some View {
        HStack(spacing: 20) {
            type.image()
                .font(.title2)
                .frame(width: 20, height: 20)
                .padding()
                .background(Color.text)
                .clipShape(RoundedRectangle(cornerRadius: 50))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(type.title())
                    .font(.caption)
                Text(type.value())
                    .bold()
                    .font(.title)
            }
        }
    }
}

extension WeatherRow {
    // MARK: Nested objects
    enum RowType {
        case minTemp(value: Double)
        case maxTemp(value: Double)
        case wind(value: Double)
        case humidity(value: Double)
        
        func title() -> String {
            switch self {
            case .minTemp: return "Min temp"
            case .maxTemp: return "Max temp"
            case .wind: return "Wind speed"
            case .humidity: return "Humidity"
            }
        }
        func image() -> Image {
            switch self {
            case .minTemp: return Image(systemName: "thermometer")
            case .maxTemp: return Image(systemName: "thermometer")
            case .wind: return Image(systemName: "wind")
            case .humidity: return Image(systemName: "humidity")
            }
        }
        func value() -> String {
            switch self {
            case .minTemp(let value): return "\(value.string())" + "°"
            case .maxTemp(let value): return "\(value.string())" + "°"
            case .wind(let value): return "\(value.string())" + "mph"
            case .humidity(let value): return "\(value.string())" + "%"
            }
        }
    }
}

struct WeatherRow_Previews: PreviewProvider {
    static var previews: some View {
        WeatherRow(type: .minTemp(value: 8))
    }
}
