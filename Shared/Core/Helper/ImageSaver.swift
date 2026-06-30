//
//  ImageSaver.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/6/22.
//

import UIKit

/// Saves a `UIImage` to the user's photo library using async/await.
/// Used by the Membership QR code screen.
final class ImageSaver: NSObject {
    private var continuation: CheckedContinuation<Void, Error>?

    /// Writes the given image to the photo album, resuming when the system reports completion.
    func writeToPhotoAlbum(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        }
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
        continuation = nil
    }
}
