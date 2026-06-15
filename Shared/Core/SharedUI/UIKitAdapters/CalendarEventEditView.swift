//
//  CalendarEventEditView.swift
//  TheLightUI
//

#if canImport(EventKitUI)
import EventKit
import EventKitUI
import SwiftUI

struct CalendarEventEditView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    let onComplete: (EKEventEditViewAction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) { }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        private let onComplete: (EKEventEditViewAction) -> Void

        init(onComplete: @escaping (EKEventEditViewAction) -> Void) {
            self.onComplete = onComplete
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            onComplete(action)
        }
    }
}
#endif
