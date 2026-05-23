//
//  NotificationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import UIKit
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: authorizationOptions) { granted, error in
            if let error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func deleteNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
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
        
        notificationCenter.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
        
        return request.identifier
    }
    
    func printNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            for request in requests {
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { continue }
                print(trigger.nextTriggerDate()?.description ?? "Invalid next trigger date")
            }
        }
    }
    
    private func makeNotificationRequest(
        title: String,
        body: String,
        categoryIdentifier: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "TheLight Software"
        content.subtitle = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        if let attachment = imageAttachment(named: "chair_2", fileExtension: "png") {
            content.attachments = [attachment]
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        return UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
    }
    
    private func imageAttachment(named name: String, fileExtension: String) -> UNNotificationAttachment? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return nil
        }
        
        return try? UNNotificationAttachment(identifier: name, url: url, options: nil)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
