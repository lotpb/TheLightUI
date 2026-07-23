//
//  LeadDetailCalendarHelpers.swift
//  TheLightUI
//

import EventKit
import SwiftUI

extension LeadDetailUI {

    // Build a calendar event using defaults from settings and customer details.
    func makeCalendarEvent() -> EKEvent {
        let event = EKEvent(eventStore: calendarEventStore)
        event.calendar = calendarEventStore.defaultCalendarForNewEvents
        event.title = calendarEventSummary
        event.startDate = detail.startDate
        event.endDate = detail.startDate.addingTimeInterval(calendarEventDurationSeconds)
        event.location = fullAddress
        event.notes = calendarEventNotes
        return event
    }

    // Title for the calendar event; uses AppStorage override or falls back to customer name.
    var calendarEventSummary: String {
        let configuredTitle = trimmed(calendarEventTitle)
        if !configuredTitle.isEmpty { return configuredTitle }
        let customerName = nonEmpty([detail.first, detail.lastname], separator: " ")
        return customerName.isEmpty ? "Appointment" : "Appt. with \(customerName)"
    }

    // Duration for the event in seconds, parsed from minutes (default 60).
    var calendarEventDurationSeconds: TimeInterval {
        let minutes = Double(trimmed(calendarEventDuration)) ?? 60
        return max(minutes, 1) * 60
    }

    // Notes to include in the event (phone, email, comments).
    var calendarEventNotes: String {
        [
            detail.phone.isEmpty ? nil : "Phone: \(detail.phone)",
            detail.email.isEmpty ? nil : "Email: \(detail.email)",
            detail.comments.isEmpty ? nil : "Comments: \(detail.comments)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}
