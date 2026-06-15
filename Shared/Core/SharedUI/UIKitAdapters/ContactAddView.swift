//
//  ContactAddView.swift
//  TheLightUI
//

#if canImport(ContactsUI)
import Contacts
import ContactsUI
import SwiftUI

struct ContactAddView: UIViewControllerRepresentable {
    let contact: CNMutableContact
    let onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = CNContactViewController(forNewContact: contact)
        controller.delegate = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        private let onComplete: () -> Void

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onComplete()
        }
    }
}
#endif
