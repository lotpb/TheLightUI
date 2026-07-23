//
//  LeadDetailPrint.swift
//  TheLightUI
//

import SwiftUI

extension LeadDetailUI {

    // HTML-formatted representation of the customer record for printing.
    var printableHTML: String {
        let name = nonEmpty([detail.first, detail.lastname], separator: " ")
        let address = fullAddress

        var fieldRows = ""
        for field in detailFields {
            let value = field.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, value != "none" else { continue }
            let escaped = value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            fieldRows += """
            <tr>
              <td class="label">\(field.label)</td>
              <td class="value">\(escaped)</td>
            </tr>
            """
        }

        let commentsSection: String
        if !detail.comments.isEmpty {
            let escaped = detail.comments
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            commentsSection = """
            <div class="comments-section">
              <div class="comments-title">Comments</div>
              <div class="comments-body">\(escaped)</div>
            </div>
            """
        } else {
            commentsSection = ""
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; margin: 40px; color: #1c1c1e; }
          .header { border-bottom: 2px solid #007aff; padding-bottom: 14px; margin-bottom: 24px; }
          .name { font-size: 26px; font-weight: 700; color: #007aff; }
          .address { font-size: 14px; color: #6e6e73; margin-top: 4px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          td { padding: 8px 12px; font-size: 14px; vertical-align: top; }
          .label { font-weight: 600; color: #3a3a3c; width: 38%; }
          .value { color: #1c1c1e; }
          .comments-section { background: #f2f2f7; border-radius: 10px; padding: 14px 16px; }
          .comments-title { font-weight: 700; font-size: 14px; color: #3a3a3c; margin-bottom: 6px; }
          .comments-body { font-size: 14px; color: #1c1c1e; line-height: 1.5; }
          .footer { margin-top: 32px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style>
        </head>
        <body>
          <div class="header">
            <div class="name">\(name.isEmpty ? "Customer Profile" : name)</div>
            \(address.isEmpty ? "" : "<div class=\"address\">\(address)</div>")
          </div>
          <table>\(fieldRows)</table>
          \(commentsSection)
          <div class="footer">Printed from The Light &bull; \(Date().formatted(date: .long, time: .omitted))</div>
        </body>
        </html>
        """
    }

    func printDetail() {
        #if canImport(UIKit)
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = nonEmpty([detail.first, detail.lastname], separator: " ")
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: printableHTML)
        controller.printFormatter = formatter
        controller.present(animated: true)
        #endif
    }
}
