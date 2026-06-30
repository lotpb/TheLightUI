//
//  ImagePicker.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 10/27/21.
//

import SwiftUI

/// UIKit image picker bridge used by SwiftUI views.
@MainActor
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    // Defaults reduce the need for a custom initializer
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var allowsEditing: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        controller.allowsEditing = allowsEditing
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: ImagePicker

        init(parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Prefer edited image when allowed, otherwise fall back to original
            parent.image = (parent.allowsEditing ? (info[.editedImage] as? UIImage) : nil) ?? (info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
