//
//  NotificationsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 24/11/22.
//

import SwiftUI

struct NotificationsView: View {
    
    @State private var mutualFundNotification: Bool
    @State private var creditCardNotification: Bool
    @State private var stockNotification: Bool
    @State private var loanNotification: Bool
    
    private var notificationController = NotificationController()
    init() {
        mutualFundNotification = notificationController.isNotificationEnabled(accountType: "Mutual Fund")
        creditCardNotification = notificationController.isNotificationEnabled(accountType: "Credit Card")
        stockNotification = notificationController.isNotificationEnabled(accountType: "Stock")
        loanNotification = notificationController.isNotificationEnabled(accountType: "Loan")
    }
    
    var body: some View {
        VStack {
            List {
                Section("Mutual Fund Notifications") {
                    Toggle("Show Notifications", isOn: $mutualFundNotification)
                        .onChange(of: mutualFundNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Mutual Fund")
                        }
                }
                Section("Credit Card Notifications") {
                    Toggle("Show Notifications", isOn: $creditCardNotification)
                        .onChange(of: creditCardNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Credit Card")
                        }
                }
                Section("Stock Notifications") {
                    Toggle("Show Notifications", isOn: $stockNotification)
                        .onChange(of: stockNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Stock")
                        }
                }
                Section("Loan Notifications") {
                    Toggle("Show Notifications", isOn: $loanNotification)
                        .onChange(of: loanNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Loan")
                        }
                }
            }
            .navigationTitle("Notifications")
            .listStyle(.inset)
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
