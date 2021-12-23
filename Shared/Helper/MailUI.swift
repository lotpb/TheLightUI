//
//  MailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 2/19/22.
//

import Foundation
import MessageUI
import SwiftUI
import UIKit

public struct MailView: UIViewControllerRepresentable {
    public struct Attachment {
        public let data: Data
        public let mimeType: String
        public let filename: String

        public init(data: Data, mimeType: String, filename: String) {
            self.data = data
            self.mimeType = mimeType
            self.filename = filename
        }
    }

    public let onResult: ((Result<MFMailComposeResult, Error>) -> Void)

    public let subject: String?
    public let message: String?
    public let attachment: Attachment?

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        public var onResult: ((Result<MFMailComposeResult, Error>) -> Void)

        init(onResult: @escaping ((Result<MFMailComposeResult, Error>) -> Void)) {
            self.onResult = onResult
        }

        public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error = error {
                self.onResult(.failure(error))
            } else {
                self.onResult(.success(result))
            }
        }
    }

    public init(
        subject: String? = nil,
        message: String? = nil,
        attachment: MailView.Attachment? = nil,
        onResult: @escaping ((Result<MFMailComposeResult, Error>) -> Void)
    ) {
        self.subject = subject
        self.message = message
        self.attachment = attachment
        self.onResult = onResult
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    public func makeUIViewController(
        context: UIViewControllerRepresentableContext<MailView>
    ) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        //controller.setCcRecipients(data.recipients)
        if let subject = subject {
            controller.setSubject(subject)
        }
        if let message = message {
            controller.setMessageBody(message, isHTML: false)
        }
        if let attachment = attachment {
            controller.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.filename
            )
        }
        return controller
    }

    public func updateUIViewController(
        _ uiViewController: MFMailComposeViewController,
        context: UIViewControllerRepresentableContext<MailView>
    ) {
        // nothing to do here
    }
}
