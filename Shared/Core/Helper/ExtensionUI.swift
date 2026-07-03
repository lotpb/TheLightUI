//
//  ExtensionUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 5/25/21.
//

// Utility helpers for app metadata, phone calls, and device model resolution.

import SwiftUI

extension OpenURLAction {
    /// Attempts to initiate a phone call by converting a raw string into a tel:// URL and opening it.
    /// Safely no-ops if the string can't be converted.
    func callPhoneNumber(_ rawValue: String) {
        guard let url = PhoneNumber(raw: rawValue).url else { return }
        self(url)
    }
}

extension UIDevice {
    // Maps a hardware identifier (e.g., "iPhone15,2") to a user-friendly model name.
    private struct DeviceModel: Decodable {
        let identifier: String
        let model: String
        
        // Loaded once from DeviceModels.json in the app bundle.
        static var all: [DeviceModel] {
            Bundle.main.decode([DeviceModel].self, from: "DeviceModels.json")
        }
    }
    
    /// Returns a user-friendly device model name, looking up the hardware identifier. Falls back to the identifier if unknown.
    var modelName: String {
        let identifier: String
        
        #if targetEnvironment(simulator)
        // Simulator exposes the model identifier via environment.
        identifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        // On real devices, derive the hardware identifier from uname().
        var systemInfo = utsname()
        uname(&systemInfo)
        identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }
        #endif
        
        // Look up a friendly name in the JSON mapping or return the raw identifier.
        return DeviceModel.all.first { $0.identifier == identifier }?.model ?? identifier
    }
}

extension Bundle {
    // App's display name from Info.plist (CFBundleName).
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Could not determine the application name"
    }
    
    // Build number from Info.plist (CFBundleVersion).
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Could not determine the application build number"
    }
    
    // Marketing version from Info.plist (CFBundleShortVersionString).
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Could not determine the application version"
    }
    
    /// Decodes a JSON resource from the bundle into a Decodable type using the provided strategies.
    func decode<T: Decodable>(
        _ type: T.Type,
        from file: String,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> T {
        // Locate the resource in the main bundle.
        guard let url = url(forResource: file, withExtension: nil) else {
            fatalError("Error: Failed to locate \(file) in bundle.")
        }
        
        // Load the raw data.
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Error: Failed to load \(file) from bundle.")
        }
        
        // Configure the decoder with supplied strategies.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        // Attempt to decode the JSON into the requested type.
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Error: Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
    }
}

