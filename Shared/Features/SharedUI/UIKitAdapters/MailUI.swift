//
//  MailUI.swift
//  TheLightUI
//

import MessageUI
import SwiftUI
import UniformTypeIdentifiers

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

    public func withAttachments(_ attachments: [MailView.Attachment]) -> MailContent {
        MailContent(
            subject: subject,
            message: message,
            isHTML: isHTML,
            recipients: recipients,
            cc: cc,
            bcc: bcc,
            attachments: self.attachments + attachments
        )
    }
}

public extension MailContent {
    static var theLightSupportSubject: String {
        let emailTitle = AppSettingsStore().emailTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return emailTitle.isEmpty ? "Email support" : emailTitle
    }

    static var theLightSupportMessage: String {
        let emailMessage = AppSettingsStore().emailMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return emailMessage.isEmpty ? defaultSupportMessage : "\(emailMessage)\n\(defaultSupportMessage)"
    }

    static let defaultSupportMessage = """
    We appreciate your support and hope the app helps make your experience simpler, smoother, and more enjoyable.

    If you have any feedback, questions, or suggestions, we would be glad to hear from you.

    Thanks again,
    TheLight Team
    """

    static func theLightSupport(recipients: [String] = []) -> MailContent {
        MailContent(
            subject: theLightSupportSubject,
            message: theLightSupportMessage,
            recipients: recipients
        )
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

public struct MailComposerButton<ButtonLabel: View>: View {
    private let content: MailContent
    private let allowedContentTypes: [UTType]
    private let allowsMultipleSelection: Bool
    private let label: ButtonLabel
    private let onResult: (Result<MFMailComposeResult, Error>) -> Void
    private let onAttachmentError: (Error) -> Void

    @State private var isFileImporterPresented = false
    @State private var isMailSheetPresented = false
    @State private var selectedAttachments: [MailView.Attachment] = []

    public init(
        content: MailContent,
        allowedContentTypes: [UTType] = [.item],
        allowsMultipleSelection: Bool = true,
        onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void = { _ in },
        onAttachmentError: @escaping (Error) -> Void = { _ in },
        @ViewBuilder label: () -> ButtonLabel
    ) {
        self.content = content
        self.allowedContentTypes = allowedContentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.label = label()
        self.onResult = onResult
        self.onAttachmentError = onAttachmentError
    }

    public var body: some View {
        Button {
            isFileImporterPresented = true
        } label: {
            label
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $isMailSheetPresented) {
            MailSheet(content: content.withAttachments(selectedAttachments), onResult: onResult)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            selectedAttachments = try urls.map(MailView.Attachment.init(fileURL:))
            isMailSheetPresented = true
        } catch {
            onAttachmentError(error)
        }
    }
}

public extension MailComposerButton where ButtonLabel == SwiftUI.Label<Text, Image> {
    init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        content: MailContent,
        allowedContentTypes: [UTType] = [.item],
        allowsMultipleSelection: Bool = true,
        onResult: @escaping (Result<MFMailComposeResult, Error>) -> Void = { _ in },
        onAttachmentError: @escaping (Error) -> Void = { _ in }
    ) {
        self.init(
            content: content,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onResult: onResult,
            onAttachmentError: onAttachmentError
        ) {
            Label(titleKey, systemImage: systemImage)
        }
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

private extension URL {
    var mailAttachmentMIMEType: String {
        let contentType = UTType(filenameExtension: pathExtension)
        return contentType?.preferredMIMEType ?? "application/octet-stream"
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

        public init(fileURL: URL) throws {
            let hasSecurityScope = fileURL.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScope {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            self.data = try Data(contentsOf: fileURL)
            self.mimeType = fileURL.mailAttachmentMIMEType
            self.filename = fileURL.lastPathComponent
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

