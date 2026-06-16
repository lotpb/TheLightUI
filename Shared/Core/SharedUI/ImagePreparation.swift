//
//  ImagePreparation.swift
//  TheLightUI
//

import Foundation
import ImageIO
import UIKit

enum ImagePreparation {
    static func preparedProfilePhoto(from data: Data) async throws -> PreparedImage {
        let jpegData = try await preparedJPEGData(
            from: data,
            maxPixelSize: 1_024,
            compressionQuality: 0.75
        )

        guard let image = UIImage(data: jpegData) else {
            throw ImagePreparationError.invalidImageData
        }

        return PreparedImage(image: image, data: jpegData)
    }

    static func preparedChatImageData(from data: Data) async throws -> Data {
        try await preparedJPEGData(
            from: data,
            maxPixelSize: 1_600,
            compressionQuality: 0.75
        )
    }

    private static func preparedJPEGData(
        from data: Data,
        maxPixelSize: CGFloat,
        compressionQuality: CGFloat
    ) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                throw ImagePreparationError.invalidImageData
            }

            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCache: false,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)
            ]

            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                throw ImagePreparationError.invalidImageData
            }

            let image = UIImage(cgImage: cgImage)
            guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else {
                throw ImagePreparationError.encodingFailed
            }

            return jpegData
        }.value
    }
}

struct PreparedImage {
    let image: UIImage
    let data: Data
}

enum ImagePreparationError: LocalizedError {
    case invalidImageData
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Could not read the selected image."
        case .encodingFailed:
            return "Could not prepare the selected image."
        }
    }
}
