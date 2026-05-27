import Foundation

/// Lightweight helper that encapsulates parsing, validation, and formatting of phone numbers
/// used for tel:// deep links. This is intentionally minimal and locale-agnostic.
struct PhoneNumber: Equatable, Hashable {
    /// Original raw string input (e.g., "(555) 123-4567", "+1 555-123-4567").
    let raw: String

    /// Normalized digits-only representation, optionally preserving a leading '+'.
    /// Examples:
    ///  - "(555) 123-4567" -> "5551234567"
    ///  - "+1 (555) 123-4567" -> "+15551234567"
    var normalized: String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        return trimmed.hasPrefix("+") ? "+" + digits : digits
    }

    /// Whether the number contains at least one dialable digit.
    var isValid: Bool { !normalized.isEmpty }

    /// tel:// URL for use with `openURL`, or nil if invalid.
    var url: URL? {
        guard isValid else { return nil }
        return URL(string: "tel://\(normalized)")
    }

    /// A lightweight, display-friendly formatted version.
    /// Falls back to the raw string if formatting cannot be applied.
    /// This is intentionally simple and non-localized.
    var formatted: String {
        // If already contains a '+', keep it as-is (international number)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.hasPrefix("+") else { return trimmed }
        // Try to format a 10-digit US-style number as (XXX) XXX-XXXX
        let digits = trimmed.filter { $0.isNumber }
        guard digits.count == 10 else { return trimmed }
        let area = digits.prefix(3)
        let mid = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(mid)-\(last)"
    }
}
