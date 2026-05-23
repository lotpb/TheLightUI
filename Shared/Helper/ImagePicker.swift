//
//  ImagePicker.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 10/27/21.
//

import SwiftUI

/// UIKit image picker bridge used by SwiftUI views.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    let sourceType: UIImagePickerController.SourceType
    let allowsEditing: Bool
    
    init(
        image: Binding<UIImage?>,
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        allowsEditing: Bool = false
    ) {
        _image = image
        self.sourceType = sourceType
        self.allowsEditing = allowsEditing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = availableSourceType
        controller.allowsEditing = allowsEditing
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    private var availableSourceType: UIImagePickerController.SourceType {
        UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = selectedImage(from: info)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        private func selectedImage(from info: [UIImagePickerController.InfoKey: Any]) -> UIImage? {
            if parent.allowsEditing, let editedImage = info[.editedImage] as? UIImage {
                return editedImage
            }
            
            return info[.originalImage] as? UIImage
        }
    }
}
