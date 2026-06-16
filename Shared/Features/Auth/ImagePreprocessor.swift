import UIKit

enum ImagePreprocessor {
    /// Prepare an image for upload by downscaling to a max dimension and compressing to JPEG.
    /// - Parameters:
    ///   - image: Source image.
    ///   - maxDimension: Longest edge in points/pixels to constrain to.
    ///   - targetMaxBytes: Optional hard cap for output size (in bytes). If provided, will iterate quality down until under the cap or minQuality is reached.
    ///   - initialQuality: Starting JPEG quality (0.0 - 1.0).
    ///   - minQuality: Minimum JPEG quality allowed when iterating.
    /// - Returns: JPEG data ready for upload, or nil on failure.
    static func prepareForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 1024,
        targetMaxBytes: Int? = nil,
        initialQuality: CGFloat = 0.75,
        minQuality: CGFloat = 0.4
    ) -> Data? {
        let downscaled = downscale(image: image, maxDimension: maxDimension)

        if let targetMaxBytes {
            var quality = initialQuality
            var data = downscaled.jpegData(compressionQuality: quality)
            while let d = data, d.count > targetMaxBytes, quality > minQuality {
                quality -= 0.1
                data = downscaled.jpegData(compressionQuality: quality)
            }
            return data
        } else {
            return downscaled.jpegData(compressionQuality: initialQuality)
        }
    }

    /// Downscale an image to fit within maxDimension while preserving aspect ratio.
    private static func downscale(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
