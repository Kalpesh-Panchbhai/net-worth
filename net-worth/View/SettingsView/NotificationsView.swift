//
//  NotificationsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 24/11/22.
//

import SwiftUI

struct NotificationsView: View {
    
    @State private var mutualFundNotification: Bool
    @State private var equityNotification: Bool
    @State private var etfNotification: Bool
    @State private var cryptoCurrencyNotification: Bool
    @State private var futureNotification: Bool
    @State private var optionNotification: Bool
    @State private var creditCardNotification: Bool
    @State private var loanNotification: Bool
    @State private var otherNotification: Bool
    
    private var notificationController = NotificationController()
    init() {
        mutualFundNotification = notificationController.isNotificationEnabled(accountType: "MUTUALFUND")
        equityNotification = notificationController.isNotificationEnabled(accountType: "EQUITY")
        etfNotification = notificationController.isNotificationEnabled(accountType: "ETF")
        cryptoCurrencyNotification = notificationController.isNotificationEnabled(accountType: "CRYPTOCURRENCY")
        futureNotification = notificationController.isNotificationEnabled(accountType: "FUTURE")
        optionNotification = notificationController.isNotificationEnabled(accountType: "OPTION")
        creditCardNotification = notificationController.isNotificationEnabled(accountType: "Credit Card")
        loanNotification = notificationController.isNotificationEnabled(accountType: "Loan")
        otherNotification = notificationController.isNotificationEnabled(accountType: "Other")
    }
    
    var body: some View {
        VStack {
            List {
                Section("Mutual Fund Notifications") {
                    Toggle("Show Notifications", isOn: $mutualFundNotification)
                        .onChange(of: mutualFundNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "MUTUALFUND")
                        }
                }
                Section("Equity Notifications") {
                    Toggle("Show Notifications", isOn: $equityNotification)
                        .onChange(of: equityNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
                        }
                }
                Section("ETF Notifications") {
                    Toggle("Show Notifications", isOn: $etfNotification)
                        .onChange(of: etfNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "ETF")
                        }
                }
                Section("Cryptocurrency Notifications") {
                    Toggle("Show Notifications", isOn: $cryptoCurrencyNotification)
                        .onChange(of: cryptoCurrencyNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
                        }
                }
                Section("Futures Notifications") {
                    Toggle("Show Notifications", isOn: $futureNotification)
                        .onChange(of: futureNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
                        }
                }
                Section("Options Notifications") {
                    Toggle("Show Notifications", isOn: $optionNotification)
                        .onChange(of: optionNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "OPTION")
                        }
                }
                Section("Credit Card Notifications") {
                    Toggle("Show Notifications", isOn: $creditCardNotification)
                        .onChange(of: creditCardNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Credit Card")
                        }
                }
                Section("Loan Notifications") {
                    Toggle("Show Notifications", isOn: $loanNotification)
                        .onChange(of: loanNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Loan")
                        }
                }
                Section("Other Notifications") {
                    Toggle("Show Notifications", isOn: $otherNotification)
                        .onChange(of: otherNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Other")
                        }
                }
            }
            .navigationTitle("Notifications")
            .listStyle(.insetGrouped)
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
