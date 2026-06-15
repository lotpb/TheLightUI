//
//  MessageComposeView.swift
//  TheLightUI
//

#if canImport(MessageUI)
import MessageUI
import SwiftUI

struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]?
    var body: String?
    var onResult: (MessageComposeResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let viewController = MFMessageComposeViewController()
        viewController.messageComposeDelegate = context.coordinator
        viewController.recipients = recipients
        viewController.body = body
        return viewController
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) { }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onResult: (MessageComposeResult) -> Void

        init(onResult: @escaping (MessageComposeResult) -> Void) {
            self.onResult = onResult
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            onResult(result)
        }
    }
}
#endif
