//
//  NotificationController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 18/11/22.
//

import Foundation
import UserNotifications

class NotificationController {
    
    private var defaultHour = 8
    
    private var notificationCenter  =  UNUserNotificationCenter.current()
    
    public func enableNotification() {
        notificationCenter.requestAuthorization(options: [.alert,
                                                          .sound,
                                                          .badge,
                                                          .criticalAlert,
                                                          .providesAppNotificationSettings]) {
                                                              (permissionGranted, error) in
                                                              if(!permissionGranted) {
                                                                  print("Permission Failed to Grant")
                                                              }else {
                                                                  print("Granted")
                                                              }
                                                          }
    }
    
    public func setNotification(id: UUID, day: Int, accountType: String, accountName: String) {
        enableNotification()
        let content = getContent(accountType: accountType, accountName: accountName)
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        dateComponents.day = day
        dateComponents.hour = defaultHour
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: id.uuidString,
                                            content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                print("Failed to add notification")
            }else {
                print("Added Notification")
            }
        }
    }
    
    public func removeNotification(id: UUID) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    private func getContent(accountType: String, accountName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = accountType
        content.body = accountName
        
        return content
    }
}
