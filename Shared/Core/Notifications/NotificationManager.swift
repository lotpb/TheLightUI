//
//  NotificationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

// Utility for requesting notification permissions, scheduling notifications,
// managing badge counts and attachments, and handling delegate presentation behavior.

import UIKit
import UserNotifications

/// Centralized helper for local notifications: authorization, scheduling, and delegate handling.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    // Singleton instance to use throughout the app.
    static let shared = NotificationManager()
    
    // Reference to the system notification center.
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // The types of notifications we request permission for.
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    
    private override init() {
        super.init()
        // Set ourselves as the delegate to control foreground presentation and responses.
        notificationCenter.delegate = self
    }
    
    /// Requests notification authorization using a completion handler.
    /// Calls back on the main thread with the result.
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        // Ask the user for permission to show alerts, play sounds, and update badges.
        notificationCenter.requestAuthorization(options: authorizationOptions) { granted, error in
            if let error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    /// Async/await wrapper around authorization request.
    func requestAuthorization() async -> Bool {
        // Bridge the completion-based API to async/await.
        await withCheckedContinuation { continuation in
            requestAuthorization { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Removes all pending (scheduled) and delivered notifications.
    func deleteNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// Schedules a calendar-based local notification.
    /// - Parameters: title, body, categoryIdentifier, dateComponents, repeats
    /// - Returns: The identifier of the scheduled request.
    @discardableResult
    func scheduleNotification(
        title: String,
        body: String,
        categoryIdentifier: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) -> String {
        let request = makeNotificationRequest(
            title: title,
            body: body,
            categoryIdentifier: categoryIdentifier,
            dateComponents: dateComponents,
            repeats: repeats
        )
        
        // Enqueue the notification request with the system.
        notificationCenter.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
        
        return request.identifier
    }
    
    /// Debug helper to print next trigger dates for all pending calendar notifications.
    func printNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            for request in requests {
                // Only interested in calendar triggers here.
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { continue }
                print(trigger.nextTriggerDate()?.description ?? "Invalid next trigger date")
            }
        }
    }
    
    /// Builds the UNNotificationRequest with content, trigger, and optional image attachment.
    private func makeNotificationRequest(
        title: String,
        body: String,
        categoryIdentifier: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) -> UNNotificationRequest {
        // Configure the notification's visible content.
        let content = UNMutableNotificationContent()
        // Static app title shown in the banner.
        content.title = "TheLight Software"
        content.subtitle = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default
        // Increment the app icon badge by one.
        content.badge = 1
        
        // Attach a local image (if available) to enrich the notification.
        if let attachment = imageAttachment(named: "chair_2", fileExtension: "png") {
            content.attachments = [attachment]
        }
        
        // Fire based on the provided date components, optionally repeating.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        return UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
    }
    
    /// Loads an image from the bundle and wraps it as a UNNotificationAttachment.
    private func imageAttachment(named name: String, fileExtension: String) -> UNNotificationAttachment? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return nil
        }
        
        return try? UNNotificationAttachment(identifier: name, url: url, options: nil)
    }
    
    /// Present notifications as a banner with sound even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound]) // Opt-in to showing banner and playing sound in foreground
    }
}
