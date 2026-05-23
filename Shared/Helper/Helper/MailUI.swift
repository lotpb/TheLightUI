//
//  MailUI.swift
//  TheLightUI
//

import MessageUI
import SwiftUI

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
    
    public static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    public let subject: String?
    public let message: String?
    public let isHTML: Bool
    public let recipients: [String]
    public let ccRecipients: [String]
    public let bccRecipients: [String]
    public let attachments: [Attachment]
    public let onResult: (Result<MFMailComposeResult, Error>) -> Void
    
    public init(
        subject: String? = nil,
        message: String? = nil,
        isHTML: Bool = false,
        recipients: [String] = [],
        ccRecipients: [String] = [],
        bccRecipients: [String] = [],
        attachment: Attachment? = nil,
        attachments: [Attachment] = [],
        onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void = { _ in }
    ) {
        self.subject = subject
        self.message = message
        self.isHTML = isHTML
        self.recipients = recipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
        self.attachments = attachments + [attachment].compactMap { $0 }
        self.onResult = onResult
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        configure(controller)
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }
    
    private func configure(_ controller: MFMailComposeViewController) {
        if let subject {
            controller.setSubject(subject)
        }
        
        if let message {
            controller.setMessageBody(message, isHTML: isHTML)
        }
        
        setRecipients(on: controller)
        addAttachments(to: controller)
    }
    
    private func setRecipients(on controller: MFMailComposeViewController) {
        if !recipients.isEmpty {
            controller.setToRecipients(recipients)
        }
        
        if !ccRecipients.isEmpty {
            controller.setCcRecipients(ccRecipients)
        }
        
        if !bccRecipients.isEmpty {
            controller.setBccRecipients(bccRecipients)
        }
    }
    
    private func addAttachments(to controller: MFMailComposeViewController) {
        for attachment in attachments {
            controller.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.filename
            )
        }
    }
    
    public final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let onResult: (Result<MFMailComposeResult, Error>) -> Void
        
        init(onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.onResult = onResult
        }
        
        public func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { [onResult] in
                if let error {
                    onResult(.failure(error))
                } else {
                    onResult(.success(result))
                }
            }
        }
    }
}
