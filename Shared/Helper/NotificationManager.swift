//
//  NotificationManager.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI
import UserNotifications
import CoreLocation  //for region

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared: NotificationManager = NotificationManager()
    let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Access Granted")
            } else {
                print("Access Not Granted")
            }
        }
    }

    func deleteNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func scheduleNotification(title: String, body: String, categoryIdentifier: String, dateComponents : DateComponents, repeats: Bool) {
        
        let content = UNMutableNotificationContent()
        content.title = "TheLight Software"
        content.subtitle = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier
        content.sound = .defaultCritical
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        if let url = Bundle.main.url(forResource: "chair_2", withExtension: "png") {
        if let attachment = try? UNNotificationAttachment(identifier: "image", url: url, options: nil) {
                                content.attachments = [attachment]
                            }
                        }
        
        ///date Notifications for night
//        var dateComponents = DateComponents()
//        dateComponents.hour = 20
//        dateComponents.minute = 51
//        dateComponents.weekday = 2
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        
        ///5 second Notification
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        ///region Notifications
//        let coordinates = CLLocationCoordinate2D(
//            latitude: 40.00,
//            longitude: 50.00)
//
//        let region = CLCircularRegion(
//            center: coordinates,
//            radius: 100,
//            identifier: UUID().uuidString)
//        region.notifyOnEntry = true
//        region.notifyOnExit = true
//        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    ///Prints to console schduled notifications
    func printNotifications() {
        print(#function)
        notificationCenter.getPendingNotificationRequests { request in
            for req in request{
                if req.trigger is UNCalendarNotificationTrigger{
                    print((req.trigger as! UNCalendarNotificationTrigger).nextTriggerDate()?.description ?? "invalid next trigger date")
                }
            }
        }
    }
    
    //MARK: UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
           completionHandler(.banner)
       }
    
}

                                                              
