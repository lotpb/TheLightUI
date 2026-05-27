//
//  MailUI.swift
//  TheLightUI
//

import MessageUI
import SwiftUI

// Simple content model to make call-sites cleaner
public struct MailContent {
    public var subject: String?
    public var message: String?
    public var isHTML: Bool
    public var recipients: [String]
    public var cc: [String]
    public var bcc: [String]
    public var attachments: [MailView.Attachment]

    public init(
        subject: String? = nil,
        message: String? = nil,
        isHTML: Bool = false,
        recipients: [String] = [],
        cc: [String] = [],
        bcc: [String] = [],
        attachments: [MailView.Attachment] = []
    ) {
        self.subject = subject
        self.message = message
        self.isHTML = isHTML
        self.recipients = recipients
        self.cc = cc
        self.bcc = bcc
        self.attachments = attachments
    }
}

/// A small SwiftUI fallback when Mail isn't configured on the device.
public struct MailUnavailableView: View {
    public init() {}
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Mail is not available on this device.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

/// A convenience wrapper that chooses between the real composer and a fallback view.
public struct MailSheet: View {
    private let content: MailContent
    private let onResult: (Result<MFMailComposeResult, Error>) -> Void

    public init(content: MailContent, onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void = { _ in }) {
        self.content = content
        self.onResult = onResult
    }

    public var body: some View {
        Group {
            if MailView.canSendMail {
                MailView(
                    subject: content.subject,
                    message: content.message,
                    isHTML: content.isHTML,
                    recipients: content.recipients,
                    ccRecipients: content.cc,
                    bccRecipients: content.bcc,
                    attachments: content.attachments,
                    onResult: onResult
                )
            } else {
                MailUnavailableView()
            }
        }
    }
}

public struct MailView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = MFMailComposeViewController

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

    public func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
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

    public init(content: MailContent, onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void = { _ in }) {
        self.subject = content.subject
        self.message = content.message
        self.isHTML = content.isHTML
        self.recipients = content.recipients
        self.ccRecipients = content.cc
        self.bccRecipients = content.bcc
        self.attachments = content.attachments
        self.onResult = onResult
    }
    
    @MainActor public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        configure(controller)
        return controller
    }
    
    @MainActor public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
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
    
    public final class Coordinator: NSObject, @MainActor MFMailComposeViewControllerDelegate {
        private let onResult: (Result<MFMailComposeResult, Error>) -> Void
        
        init(onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
            self.onResult = onResult
        }
        
        public nonisolated func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            Task { @MainActor in
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
}

