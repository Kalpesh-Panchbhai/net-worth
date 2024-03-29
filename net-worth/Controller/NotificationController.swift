//
//  NotificationController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 18/11/22.
//

import Foundation
import UserNotifications

class NotificationController {
    
    var defaultHour = 8
    var granted: Bool = false
    
    public func getGranted() -> Bool {
        return granted
    }
    
    init() {
        enableNotification()
    }
    
    var notificationCenter  =  UNUserNotificationCenter.current()
    
    public func isNotificationEnabled(accountType: String) -> Bool {
        return UserDefaults.standard.bool(forKey: accountType)
    }
    
    private func enableNotification() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert,
                                                                               .sound,
                                                                               .badge,
                                                                               .criticalAlert,
                                                                               .providesAppNotificationSettings])
        } catch {
            print(error)
        }
        return false
    }
    
    private func enableNotification() {
        Task {
            granted = await enableNotification()
        }
    }
    
    private func getContent(accountType: String, accountName: String) -> UNMutableNotificationContent {
        if(accountType == ConstantUtils.creditCardAccountType) {
            return getCreditCardContent(accountName: accountName)
        } else if(accountType == ConstantUtils.loanAccountType) {
            return getLoanContent(accountName: accountName)
        } else if(accountType == ConstantUtils.otherAccountType) {
            return getOtherContent(accountName: accountName)
        } else {
            return getSymbolContent(accountName: accountName)
        }
    }
    
    private func getCreditCardContent(accountName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = accountName + " Credit Card Bill Generated"
        content.body = "Please pay before due date to avoid late fees."
        content.sound = .default
        
        let open = UNNotificationAction(identifier: "open", title: "Open")
        let cancel = UNNotificationAction(identifier: "cancel", title: "cancel")
        
        let category = UNNotificationCategory(identifier: "action", actions: [open, cancel], intentIdentifiers: [])
        notificationCenter.setNotificationCategories([category])
        content.categoryIdentifier = "action"
        
        return content
    }
    
    private func getLoanContent(accountName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = accountName + " Loan"
        content.body = "EMI will be deducted today."
        content.sound = .default
        return content
    }
    
    private func getOtherContent(accountName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = accountName
        content.body = "Payment reminder."
        content.sound = .default
        return content
    }
    
    private func getSymbolContent(accountName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = accountName
        content.body = "Payment reminder."
        content.sound = .default
        return content
    }
    
    public func setNotification(id: String, day: Int, accountType: String, accountName: String) {
        if(isNotificationEnabled(accountType: accountType)) {
            let content = getContent(accountType: accountType, accountName: accountName)
            
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            
            dateComponents.day = day
            dateComponents.hour = defaultHour
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: id,
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
    }
    
    public func setNotification(newValue: Bool, accountType: String) {
        UserDefaults.standard.set(newValue, forKey: accountType)
        let accountList = AccountController().getAccountList(accountType: accountType)
        if(newValue) {
            for account in accountList {
                if(account.paymentReminder){
                    setNotification(id: account.id!, day: account.paymentDate, accountType: account.accountType, accountName: account.accountName)
                }
            }
        }else {
            for account in accountList {
                removeNotification(id: account.id!)
            }
        }
    }
    
    public func enableNotification(account: Account) {
        setNotification(id: account.id!, day: account.paymentDate, accountType: account.accountType, accountName: account.accountName)
    }
    
    public func removeNotification(id: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
