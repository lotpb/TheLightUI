//
//  MapFormatting.swift
//  TheLightUI
//

import CoreLocation
import Foundation

/// Shared formatting for map distance, travel time, and speed values.
enum MapFormat {
    static func distance(_ meters: CLLocationDistance) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = [.providedUnit]

        let measurementSystem = Locale.current.measurementSystem
        let isMetric = measurementSystem == .metric || measurementSystem == .uk
        let targetUnit: UnitLength = isMetric ? .kilometers : .miles
        let converted = measurement.converted(to: targetUnit)

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter = numberFormatter

        return formatter.string(from: converted)
    }

    static func travelTime(_ travelTime: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = travelTime >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: max(travelTime, 60)) ?? "1 min"
    }

    static func speed(_ metersPerSecond: CLLocationSpeed) -> String {
        Measurement(value: max(metersPerSecond, 0), unit: UnitSpeed.metersPerSecond)
            .converted(to: .milesPerHour)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}
